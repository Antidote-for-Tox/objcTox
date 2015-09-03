//
//  OCTRealmManager.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 22.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Realm/Realm.h>

#import "OCTRealmManager.h"
#import "RBQFetchRequest.h"
#import "RBQRealmNotificationManager.h"
#import "OCTFriend.h"
#import "OCTChat.h"
#import "OCTMessageAbstract.h"
#import "OCTMessageText.h"
#import "OCTMessageFile.h"

#import "DDLog.h"
#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

static const uint64_t kCurrentSchemeVersion = 1;

@interface OCTRealmManager ()

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) RLMRealm *realm;

@end

@implementation OCTRealmManager

#pragma mark -  Lifecycle

- (instancetype)initWithDatabasePath:(NSString *)path
{
    NSParameterAssert(path);

    self = [super init];

    if (! self) {
        return nil;
    }

    DDLogInfo(@"OCTRealmManager: init with path %@", path);

    _queue = dispatch_queue_create("OCTRealmManager queue", NULL);

    __weak OCTRealmManager *weakSelf = self;
    dispatch_sync(_queue, ^{
        __strong OCTRealmManager *strongSelf = weakSelf;

        RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
        configuration.path = path;
        configuration.schemaVersion = kCurrentSchemeVersion;
        configuration.migrationBlock = [strongSelf realmMigrationBlock];

        NSError *error;
        strongSelf->_realm = [RLMRealm realmWithConfiguration:configuration error:&error];

        if (! strongSelf->_realm) {
            DDLogInfo(@"OCTRealmManager: init failed with error %@", error);
        }
    });

    return self;
}

#pragma mark -  Public

- (NSString *)path
{
    return self.realm.path;
}

#pragma mark -  Basic methods

- (OCTObject *)objectWithUniqueIdentifier:(NSString *)uniqueIdentifier class:(Class)class
{
    NSParameterAssert(uniqueIdentifier);
    NSParameterAssert(class);

    __block OCTObject *object = nil;

    dispatch_sync(self.queue, ^{
        object = [class objectInRealm:self.realm forPrimaryKey:uniqueIdentifier];
    });

    return object;
}

- (RBQFetchRequest *)fetchRequestForClass:(Class)class withPredicate:(NSPredicate *)predicate
{
    NSParameterAssert(class);

    __block RBQFetchRequest *fetchRequest = nil;

    DDLogVerbose(@"OCTRealmManager: fetchRequestForClass %@ withPredicate %@", class, predicate);

    dispatch_sync(self.queue, ^{
        fetchRequest = [RBQFetchRequest fetchRequestWithEntityName:NSStringFromClass(class)
                                                           inRealm:self.realm
                                                         predicate:predicate];
    });

    return fetchRequest;
}

- (void)updateObject:(OCTObject *)object withBlock:(void (^)(id theObject))updateBlock
{
    NSParameterAssert(object);
    NSParameterAssert(updateBlock);

    DDLogInfo(@"OCTRealmManager: updateObject %@", object);

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];

        updateBlock(object);
        [[self logger] didChangeObject:object];

        [self.realm commitWriteTransaction];
    });
}

- (void)updateObjectsWithoutNotification:(void (^)())updateBlock
{
    NSParameterAssert(updateBlock);

    DDLogInfo(@"OCTRealmManager: updating objects without notification");

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];
        updateBlock();
        [self.realm commitWriteTransaction];
    });
}

- (void)addObject:(OCTObject *)object
{
    NSParameterAssert(object);

    DDLogInfo(@"OCTRealmManager: add object %@", object);

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];

        [self.realm addObject:object];
        [[self logger] didAddObject:object];

        [self.realm commitWriteTransaction];
    });
}

- (void)deleteObject:(OCTObject *)object
{
    NSParameterAssert(object);

    DDLogInfo(@"OCTRealmManager: delete object %@", object);

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];

        [[self logger] willDeleteObject:object];
        [self.realm deleteObject:object];

        [self.realm commitWriteTransaction];
    });
}

#pragma mark -  Other methods

- (OCTFriend *)friendWithFriendNumber:(OCTToxFriendNumber)friendNumber
{
    __block OCTFriend *friend;

    dispatch_sync(self.queue, ^{
        friend = [[OCTFriend objectsInRealm:self.realm where:@"friendNumber == %d", friendNumber] firstObject];
    });

    return friend;
}

- (OCTChat *)getOrCreateChatWithFriend:(OCTFriend *)friend
{
    __block OCTChat *chat = nil;

    dispatch_sync(self.queue, ^{
        // TODO add this (friends.@count == 1) condition. Currentry Realm doesn't support collection queries
        // See https://github.com/realm/realm-cocoa/issues/1490
        chat = [[OCTChat objectsInRealm:self.realm where:@"ANY friends == %@", friend] firstObject];

        if (chat) {
            return;
        }

        DDLogInfo(@"OCTRealmManager: creating chat with friend %@", friend);

        chat = [OCTChat new];
        chat.lastActivityDateInterval = [[NSDate date] timeIntervalSince1970];

        [self.realm beginWriteTransaction];

        [self.realm addObject:chat];
        [chat.friends addObject:friend];
        [[self logger] didAddObject:chat];

        [self.realm commitWriteTransaction];
    });

    return chat;
}

- (void)removeChatWithAllMessages:(OCTChat *)chat
{
    NSParameterAssert(chat);

    DDLogInfo(@"OCTRealmManager: removing chat with all messages %@", chat);

    dispatch_sync(self.queue, ^{
        RLMResults *messages = [OCTMessageAbstract objectsInRealm:self.realm where:@"chat == %@", chat];
        RBQRealmChangeLogger *logger = [self logger];

        [self.realm beginWriteTransaction];
        for (OCTMessageAbstract *message in messages) {
            if (message.messageText) {
                [logger willDeleteObject:message.messageText];
                [self.realm deleteObject:message.messageText];
            }
            if (message.messageFile) {
                [logger willDeleteObject:message.messageFile];
                [self.realm deleteObject:message.messageFile];
            }
        }

        [logger willDeleteObjects:messages];
        [self.realm deleteObjects:messages];

        [logger willDeleteObject:chat];
        [self.realm deleteObject:chat];

        [self.realm commitWriteTransaction];
    });
}

- (OCTMessageAbstract *)addMessageWithText:(NSString *)text
                                      type:(OCTToxMessageType)type
                                      chat:(OCTChat *)chat
                                    sender:(OCTFriend *)sender
                                 messageId:(OCTToxMessageId)messageId
{
    NSParameterAssert(text);
    NSParameterAssert(chat);

    DDLogInfo(@"OCTRealmManager: adding messageText to chat %@", chat);

    OCTMessageText *messageText = [OCTMessageText new];
    messageText.text = text;
    messageText.isDelivered = NO;
    messageText.type = type;
    messageText.messageId = messageId;

    OCTMessageAbstract *messageAbstract = [OCTMessageAbstract new];
    messageAbstract.dateInterval = [[NSDate date] timeIntervalSince1970];
    messageAbstract.sender = sender;
    messageAbstract.chat = chat;
    messageAbstract.messageText = messageText;

    [self addObject:messageAbstract];

    [self updateObject:chat withBlock:^(OCTChat *theChat) {
        theChat.lastMessage = messageAbstract;
        theChat.lastActivityDateInterval = messageAbstract.dateInterval;
    }];

    return messageAbstract;
}

#pragma mark -  Private

- (RLMMigrationBlock)realmMigrationBlock
{
    return ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
               if (oldSchemaVersion < 1) {
                   // objcTox version 0.1.0
               }
    };
}

- (RBQRealmChangeLogger *)logger
{
    return [RBQRealmChangeLogger loggerForRealm:self.realm];
}

@end
