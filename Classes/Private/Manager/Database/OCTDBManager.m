//
//  OCTDBManager.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Realm/Realm.h>

#import "OCTDBManager.h"

@interface OCTDBManager()

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) RLMRealm *realm;

@end

@implementation OCTDBManager

#pragma mark -  Lifecycle

- (instancetype)initWithDatabasePath:(NSString *)path
{
    NSParameterAssert(path);

    self = [super init];

    if (! self) {
        return nil;
    }

    _queue = dispatch_queue_create("OCTDBManager queue", NULL);

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

- (void)updateDBObjectInBlock:(void (^)())updateBlock
{
    NSParameterAssert(updateBlock);

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];
        updateBlock();
        [self.realm commitWriteTransaction];
    });
}

#pragma mark -  Friend requests

- (RLMResults *)allFriendRequests
{
    __block RLMResults *results = nil;

    dispatch_sync(self.queue, ^{
        results = [OCTDBFriendRequest allObjectsInRealm:self.realm];
    });

    return results;
}

- (void)addFriendRequest:(OCTDBFriendRequest *)friendRequest
{
    NSParameterAssert(friendRequest.publicKey);

    dispatch_sync(self.queue, ^{
        [self.realm beginWriteTransaction];
        [self.realm addObject:friendRequest];
        [self.realm commitWriteTransaction];
    });
}

- (void)removeFriendRequestWithPublicKey:(NSString *)publicKey
{
    NSParameterAssert(publicKey);

    dispatch_sync(self.queue, ^{
        OCTDBFriendRequest *db = [OCTDBFriendRequest objectInRealm:self.realm forPrimaryKey:publicKey];

        if (! db) {
            return;
        }

        [self.realm beginWriteTransaction];
        [self.realm deleteObject:db];
        [self.realm commitWriteTransaction];
    });
}

#pragma mark -  Friends

- (OCTDBFriend *)getOrCreateFriendWithFriendNumber:(NSInteger)friendNumber
{
    __block OCTDBFriend *friend;

    dispatch_sync(self.queue, ^{
        friend = [OCTDBFriend new];
        friend.friendNumber = friendNumber;

        [self.realm beginWriteTransaction];
        friend = [OCTDBFriend createOrUpdateInRealm:self.realm withValue:friend];
        [self.realm commitWriteTransaction];
    });

    return friend;
}

#pragma mark -  Chats

- (RLMResults *)allChats
{
    __block RLMResults *results;

    dispatch_sync(self.queue, ^{
        results = [OCTDBChat allObjectsInRealm:self.realm];
    });

    return results;
}

- (OCTDBChat *)getOrCreateChatWithFriendNumber:(NSInteger)friendNumber
{
    OCTDBFriend *friend = [self getOrCreateFriendWithFriendNumber:friendNumber];

    __block OCTDBChat *chat = nil;

    dispatch_sync(self.queue, ^{
        // TODO add this (friends.@count == 1) condition. Currentry Realm doesn't support collection queries
        // See https://github.com/realm/realm-cocoa/issues/1490
        // chat = [[OCTDBChat objectsInRealm:self.realm
        //                             where:@"friends.@count == 1 AND ANY friends == %@", friend] lastObject];

        chat = [[OCTDBChat objectsInRealm:self.realm where:@"ANY friends == %@", friend] lastObject];

        if (! chat) {
            chat = [OCTDBChat new];
            chat.lastMessage = nil;

            [self.realm beginWriteTransaction];
            [self.realm addObject:chat];
            [chat.friends addObject:friend];
            [self.realm commitWriteTransaction];
        }
    });

    return chat;
}

- (OCTDBChat *)chatWithUniqueIdentifier:(NSString *)uniqueIdentifier
{
    __block OCTDBChat *chat = nil;

    dispatch_sync(self.queue, ^{
        chat = [OCTDBChat objectInRealm:self.realm forPrimaryKey:uniqueIdentifier];
    });

    return chat;
}

#pragma mark -  Messages

- (RLMResults *)allMessagesInChat:(OCTDBChat *)chat
{
    NSParameterAssert(chat);

    __block RLMResults *results;

    dispatch_sync(self.queue, ^{
        results = [OCTDBMessageAbstract objectsInRealm:self.realm where:@"chat == %@", chat];
    });

    return results;
}

- (void)addMessageWithText:(NSString *)text type:(OCTToxMessageType)type chat:(OCTDBChat *)chat sender:(OCTDBFriend *)sender
{
    [self addMessageWithText:text type:type chat:chat sender:sender messageId:-1];
}

- (void)addMessageWithText:(NSString *)text
                      type:(OCTToxMessageType)type
                      chat:(OCTDBChat *)chat
                    sender:(OCTDBFriend *)sender
                 messageId:(int)messageId
{
    dispatch_sync(self.queue, ^{
        OCTDBMessageAbstract *message = [OCTDBMessageAbstract new];
        message.dateInterval = [[NSDate date] timeIntervalSince1970];
        message.sender = sender;
        message.chat = chat;
        message.textMessage = [OCTDBMessageText new];
        message.textMessage.text = text;
        message.textMessage.isDelivered = NO;
        message.textMessage.type = type;
        message.textMessage.messageId = messageId;

        [self.realm beginWriteTransaction];
        [self.realm addObject:message];
        [self.realm commitWriteTransaction];
    });
}

@end
