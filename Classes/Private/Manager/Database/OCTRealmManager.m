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

    _queue = dispatch_queue_create("OCTRealmManager queue", NULL);

    dispatch_sync(_queue, ^{
        _realm = [RLMRealm realmWithPath:path];
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

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];
        updateBlock(object);
        [self.realm commitWriteTransaction];

        [[self logger] didChangeObject:object];
    });
}

- (void)updateObjectsWithoutNotification:(void (^)())updateBlock
{
    NSParameterAssert(updateBlock);

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];
        updateBlock();
        [self.realm commitWriteTransaction];
    });
}

- (void)addObject:(OCTObject *)object
{
    NSParameterAssert(object);

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];
        [self.realm addObject:object];
        [self.realm commitWriteTransaction];

        [[self logger] didAddObject:object];
    });
}

- (void)deleteObject:(OCTObject *)object
{
    NSParameterAssert(object);

    dispatch_sync(self.queue, ^{
        [[self logger] willDeleteObject:object];

        [self.realm beginWriteTransaction];
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

        chat = [OCTChat new];
        chat.enteredText = @"";

        [self.realm beginWriteTransaction];
        [self.realm addObject:chat];
        [chat.friends addObject:friend];
        [self.realm commitWriteTransaction];

        [[self logger] didAddObject:chat];
    });

    return chat;
}

- (void)removeChatWithAllMessages:(OCTChat *)chat
{
    NSParameterAssert(chat);

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

    [self addObject:messageText];
    [self addObject:messageAbstract];

    [self updateObject:chat withBlock:^(OCTChat *theChat) {
        theChat.lastMessage = messageAbstract;
    }];

    return messageAbstract;
}

#pragma mark -  Private

- (RBQRealmChangeLogger *)logger
{
    return [RBQRealmChangeLogger loggerForRealm:self.realm];
}

@end
