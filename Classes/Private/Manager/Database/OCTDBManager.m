//
//  OCTDBManager.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Realm/Realm.h>

#import "OCTDBManager.h"
#import "OCTDBFriendRequest.h"

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

- (NSArray *)friendRequests
{
    __block NSArray *friendRequests = nil;

    dispatch_sync(self.queue, ^{
        RLMResults *results = [OCTDBFriendRequest allObjectsInRealm:self.realm];
        results = [results sortedResultsUsingProperty:@"publicKey" ascending:YES];

        NSMutableArray *array = [NSMutableArray new];

        for (OCTDBFriendRequest *db in results) {
            [array addObject:[db friendRequest]];
        }

        friendRequests = [array copy];
    });

    return friendRequests;
}

- (void)addFriendRequest:(OCTFriendRequest *)friendRequest
{
    NSParameterAssert(friendRequest.publicKey);

    dispatch_sync(self.queue, ^{
        OCTDBFriendRequest *db = [OCTDBFriendRequest createFromFriendRequest:friendRequest];

        [self.realm beginWriteTransaction];
        [self.realm addObject:db];
        [self.realm commitWriteTransaction];
    });
}

- (void)removeFriendRequest:(OCTFriendRequest *)friendRequest
{
    NSParameterAssert(friendRequest.publicKey);

    dispatch_sync(self.queue, ^{
        OCTDBFriendRequest *db = [OCTDBFriendRequest objectInRealm:self.realm forPrimaryKey:friendRequest.publicKey];

        if (! db) {
            return;
        }

        [self.realm beginWriteTransaction];
        [self.realm deleteObject:db];
        [self.realm commitWriteTransaction];
    });
}

@end
