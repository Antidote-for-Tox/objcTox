//
//  OCTRealmManager.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 22.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Realm/Realm.h>

#import "OCTRealmManager.h"
#import "OCTFriend.h"
#import "OCTFriendRequest.h"
#import "OCTChat.h"
#import "OCTCall.h"
#import "OCTMessageAbstract.h"
#import "OCTMessageText.h"
#import "OCTMessageFile.h"
#import "OCTMessageCall.h"
#import "OCTSettingsStorageObject.h"
#import "OCTLogging.h"

static const uint64_t kCurrentSchemeVersion = 5;
static NSString *kSettingsStorageObjectPrimaryKey = @"kSettingsStorageObjectPrimaryKey";

@interface OCTRealmManager ()

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) RLMRealm *realm;

@end

@implementation OCTRealmManager
@synthesize settingsStorage = _settingsStorage;

#pragma mark -  Lifecycle

- (instancetype)initWithDatabaseFileURL:(NSURL *)fileURL
{
    NSParameterAssert(fileURL);

    self = [super init];

    if (! self) {
        return nil;
    }

    OCTLogInfo(@"init with fileURL %@", fileURL);

    _queue = dispatch_queue_create("OCTRealmManager queue", NULL);

    __weak OCTRealmManager *weakSelf = self;
    dispatch_sync(_queue, ^{
        __strong OCTRealmManager *strongSelf = weakSelf;

        [strongSelf createRealmWithFileURL:fileURL];
        [strongSelf createSettingsStorage];
    });

    [self convertAllCallsToMessages];

    return self;
}

#pragma mark -  Public

- (NSURL *)realmFileURL
{
    return self.realm.configuration.fileURL;
}

#pragma mark -  Basic methods

- (id)objectWithUniqueIdentifier:(NSString *)uniqueIdentifier class:(Class)class
{
    NSParameterAssert(uniqueIdentifier);
    NSParameterAssert(class);

    __block OCTObject *object = nil;

    dispatch_sync(self.queue, ^{
        object = [class objectInRealm:self.realm forPrimaryKey:uniqueIdentifier];
    });

    return object;
}

- (RLMResults *)objectsWithClass:(Class)class predicate:(NSPredicate *)predicate
{
    NSParameterAssert(class);

    __block RLMResults *results;

    dispatch_sync(self.queue, ^{
        results = [class objectsInRealm:self.realm withPredicate:predicate];
    });

    return results;
}

- (void)updateObject:(OCTObject *)object withBlock:(void (^)(id theObject))updateBlock
{
    NSParameterAssert(object);
    NSParameterAssert(updateBlock);

    OCTLogInfo(@"updateObject %@", object);

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];

        updateBlock(object);

        [self.realm commitWriteTransaction];
    });
}

- (void)updateObjectsWithClass:(Class)class
                     predicate:(NSPredicate *)predicate
                   updateBlock:(void (^)(id theObject))updateBlock
{
    NSParameterAssert(class);
    NSParameterAssert(updateBlock);

    OCTLogInfo(@"updating objects of class %@ with predicate %@", NSStringFromClass(class), predicate);

    dispatch_sync(self.queue, ^{
        RLMResults *results = [class objectsInRealm:self.realm withPredicate:predicate];

        [self.realm beginWriteTransaction];
        for (id object in results) {
            updateBlock(object);
        }
        [self.realm commitWriteTransaction];
    });
}

- (void)addObject:(OCTObject *)object
{
    NSParameterAssert(object);

    OCTLogInfo(@"add object %@", object);

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];

        [self.realm addObject:object];

        [self.realm commitWriteTransaction];
    });
}

- (void)deleteObject:(OCTObject *)object
{
    NSParameterAssert(object);

    OCTLogInfo(@"delete object %@", object);

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];

        [self.realm deleteObject:object];

        [self.realm commitWriteTransaction];
    });
}

#pragma mark -  Other methods

- (void)createRealmWithFileURL:(NSURL *)fileURL
{
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.fileURL = fileURL;
    configuration.schemaVersion = kCurrentSchemeVersion;
    configuration.migrationBlock = [self realmMigrationBlock];

    NSError *error;
    self->_realm = [RLMRealm realmWithConfiguration:configuration error:&error];

    if (! self->_realm) {
        OCTLogInfo(@"init failed with error %@", error);
    }
}

- (void)createSettingsStorage
{
    _settingsStorage = [OCTSettingsStorageObject objectInRealm:self.realm
                                                 forPrimaryKey:kSettingsStorageObjectPrimaryKey];

    if (! _settingsStorage) {
        OCTLogInfo(@"no _settingsStorage, creating it");
        _settingsStorage = [OCTSettingsStorageObject new];
        _settingsStorage.uniqueIdentifier = kSettingsStorageObjectPrimaryKey;

        [self.realm beginWriteTransaction];
        [self.realm addObject:_settingsStorage];
        [self.realm commitWriteTransaction];
    }
}

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

        OCTLogInfo(@"creating chat with friend %@", friend);

        chat = [OCTChat new];
        chat.lastActivityDateInterval = [[NSDate date] timeIntervalSince1970];

        [self.realm beginWriteTransaction];

        [self.realm addObject:chat];
        [chat.friends addObject:friend];

        [self.realm commitWriteTransaction];
    });

    return chat;
}

- (OCTCall *)createCallWithChat:(OCTChat *)chat status:(OCTCallStatus)status
{
    __block OCTCall *call = nil;

    dispatch_sync(self.queue, ^{

        call = [[OCTCall objectsInRealm:self.realm where:@"chat == %@", chat] firstObject];

        if (call) {
            return;
        }

        OCTLogInfo(@"creating call with chat %@", chat);

        call = [OCTCall new];
        call.status = status;
        call.chat = chat;

        [self.realm beginWriteTransaction];
        [self.realm addObject:call];
        [self.realm commitWriteTransaction];
    });

    return call;
}

- (OCTCall *)getCurrentCallForChat:(OCTChat *)chat
{
    __block OCTCall *call = nil;

    dispatch_sync(self.queue, ^{

        call = [[OCTCall objectsInRealm:self.realm where:@"chat == %@", chat] firstObject];
    });

    return call;
}

- (void)removeChatWithAllMessages:(OCTChat *)chat
{
    NSParameterAssert(chat);

    OCTLogInfo(@"removing chat with all messages %@", chat);

    dispatch_sync(self.queue, ^{
        RLMResults *messages = [OCTMessageAbstract objectsInRealm:self.realm where:@"chat == %@", chat];

        [self.realm beginWriteTransaction];
        for (OCTMessageAbstract *message in messages) {
            if (message.messageText) {
                [self.realm deleteObject:message.messageText];
            }
            if (message.messageFile) {
                [self.realm deleteObject:message.messageFile];
            }
            if (message.messageCall) {
                [self.realm deleteObject:message.messageCall];
            }
        }

        [self.realm deleteObjects:messages];
        [self.realm deleteObject:chat];

        [self.realm commitWriteTransaction];
    });
}

- (void)convertAllCallsToMessages
{
    RLMResults *calls = [OCTCall allObjectsInRealm:self.realm];

    OCTLogInfo(@"removing %lu calls", (unsigned long)calls.count);

    for (OCTCall *call in calls) {
        [self addMessageCall:call];
    }

    [self.realm beginWriteTransaction];
    [self.realm deleteObjects:calls];
    [self.realm commitWriteTransaction];
}

- (OCTMessageAbstract *)addMessageWithText:(NSString *)text
                                      type:(OCTToxMessageType)type
                                      chat:(OCTChat *)chat
                                    sender:(OCTFriend *)sender
                                 messageId:(OCTToxMessageId)messageId
{
    NSParameterAssert(text);

    OCTLogInfo(@"adding messageText to chat %@", chat);

    OCTMessageText *messageText = [OCTMessageText new];
    messageText.text = text;
    messageText.isDelivered = NO;
    messageText.type = type;
    messageText.messageId = messageId;

    return [self addMessageAbstractWithChat:chat sender:sender messageText:messageText messageFile:nil messageCall:nil];
}

- (OCTMessageAbstract *)addMessageWithFileNumber:(OCTToxFileNumber)fileNumber
                                        fileType:(OCTMessageFileType)fileType
                                        fileSize:(OCTToxFileSize)fileSize
                                        fileName:(NSString *)fileName
                                        filePath:(NSString *)filePath
                                         fileUTI:(NSString *)fileUTI
                                            chat:(OCTChat *)chat
                                          sender:(OCTFriend *)sender
{
    OCTLogInfo(@"adding messageFile to chat %@, fileSize %lld", chat, fileSize);

    OCTMessageFile *messageFile = [OCTMessageFile new];
    messageFile.internalFileNumber = fileNumber;
    messageFile.fileType = fileType;
    messageFile.fileSize = fileSize;
    messageFile.fileName = fileName;
    [messageFile internalSetFilePath:filePath];
    messageFile.fileUTI = fileUTI;

    return [self addMessageAbstractWithChat:chat sender:sender messageText:nil messageFile:messageFile messageCall:nil];
}

- (OCTMessageAbstract *)addMessageCall:(OCTCall *)call
{
    OCTLogInfo(@"adding messageCall to call %@", call);

    OCTMessageCallEvent event;
    switch (call.status) {
        case OCTCallStatusDialing:
        case OCTCallStatusRinging:
            event = OCTMessageCallEventUnanswered;
            break;
        case OCTCallStatusActive:
            event = OCTMessageCallEventAnswered;
            break;
    }

    OCTMessageCall *messageCall = [OCTMessageCall new];
    messageCall.callDuration = call.callDuration;
    messageCall.callEvent = event;

    return [self addMessageAbstractWithChat:call.chat sender:call.caller messageText:nil messageFile:nil messageCall:messageCall];
}

#pragma mark -  Private

- (RLMMigrationBlock)realmMigrationBlock
{
    return ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
               if (oldSchemaVersion < 1) {
                   // objcTox version 0.1.0
               }

               if (oldSchemaVersion < 2) {
                   // objcTox version 0.2.1
               }

               if (oldSchemaVersion < 3) {
                   // objcTox version 0.4.0
               }

               if (oldSchemaVersion < 4) {
                   // objcTox version 0.5.0
                   [self doMigrationVersion4:migration];
               }

               if (oldSchemaVersion < 5) {
                   // objcTox verson 0.7.0
                   [self doMigrationVersion5:migration];
               }
    };
}

- (void)doMigrationVersion4:(RLMMigration *)migration
{
    [migration enumerateObjects:OCTChat.className block:^(RLMObject *oldObject, RLMObject *newObject) {
        newObject[@"enteredText"] = [oldObject[@"enteredText"] length] > 0 ? oldObject[@"enteredText"] : nil;
    }];

    [migration enumerateObjects:OCTFriend.className block:^(RLMObject *oldObject, RLMObject *newObject) {
        newObject[@"name"] = [oldObject[@"name"] length] > 0 ? oldObject[@"name"] : nil;
        newObject[@"statusMessage"] = [oldObject[@"statusMessage"] length] > 0 ? oldObject[@"statusMessage"] : nil;
    }];

    [migration enumerateObjects:OCTFriendRequest.className block:^(RLMObject *oldObject, RLMObject *newObject) {
        newObject[@"message"] = [oldObject[@"message"] length] > 0 ? oldObject[@"message"] : nil;
    }];

    [migration enumerateObjects:OCTMessageFile.className block:^(RLMObject *oldObject, RLMObject *newObject) {
        newObject[@"fileName"] = [oldObject[@"fileName"] length] > 0 ? oldObject[@"fileName"] : nil;
        newObject[@"fileUTI"] = [oldObject[@"fileUTI"] length] > 0 ? oldObject[@"fileUTI"] : nil;
    }];

    [migration enumerateObjects:OCTMessageText.className block:^(RLMObject *oldObject, RLMObject *newObject) {
        newObject[@"text"] = [oldObject[@"text"] length] > 0 ? oldObject[@"text"] : nil;
    }];
}

- (void)doMigrationVersion5:(RLMMigration *)migration
{
    [migration enumerateObjects:OCTMessageAbstract.className block:^(RLMObject *oldObject, RLMObject *newObject) {
        newObject[@"chatUniqueIdentifier"] = oldObject[@"chat"][@"uniqueIdentifier"];
        newObject[@"senderUniqueIdentifier"] = oldObject[@"sender"][@"uniqueIdentifier"];
    }];
}

/**
 * Only one of messageText, messageFile or messageCall can be non-nil.
 */
- (OCTMessageAbstract *)addMessageAbstractWithChat:(OCTChat *)chat
                                            sender:(OCTFriend *)sender
                                       messageText:(OCTMessageText *)messageText
                                       messageFile:(OCTMessageFile *)messageFile
                                       messageCall:(OCTMessageCall *)messageCall
{
    NSParameterAssert(chat);

    NSAssert( (messageText && ! messageFile && ! messageCall) ||
              (! messageText && messageFile && ! messageCall) ||
              (! messageText && ! messageFile && messageCall),
              @"Wrong options passed. Only one of messageText, messageFile or messageCall should be non-nil.");

    OCTMessageAbstract *messageAbstract = [OCTMessageAbstract new];
    messageAbstract.dateInterval = [[NSDate date] timeIntervalSince1970];
    messageAbstract.senderUniqueIdentifier = sender.uniqueIdentifier;
    messageAbstract.chatUniqueIdentifier = chat.uniqueIdentifier;
    messageAbstract.messageText = messageText;
    messageAbstract.messageFile = messageFile;
    messageAbstract.messageCall = messageCall;

    [self addObject:messageAbstract];

    [self updateObject:chat withBlock:^(OCTChat *theChat) {
        theChat.lastMessage = messageAbstract;
        theChat.lastActivityDateInterval = messageAbstract.dateInterval;
    }];

    return messageAbstract;
}

@end
