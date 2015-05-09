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
        friend = [OCTDBFriend createOrUpdateInRealm:self.realm withObject:friend];
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

@end
