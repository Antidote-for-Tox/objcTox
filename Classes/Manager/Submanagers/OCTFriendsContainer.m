//
//  OCTFriendsContainer.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTFriendsContainer.h"

NSString *const kOCTFriendsContainerUpdateFriendsNotification = @"kOCTToxFriendsContainerUpdateFriendsNotification";

NSString *const kOCTFriendsContainerUpdateKeyInsertedSet = @"kOCTToxFriendsContainerUpdateKeyInsertedSet";
NSString *const kOCTFriendsContainerUpdateKeyRemovedSet = @"kOCTToxFriendsContainerUpdateKeyRemovedSet";
NSString *const kOCTFriendsContainerUpdateKeyUpdatedSet = @"kOCTToxFriendsContainerUpdateKeyUpdatedSet";

static NSString *const kSortStorageKey = @"OCTFriendsContainer.sortStorageKey";

@interface OCTFriendsContainer()

@property (strong, nonatomic) NSMutableArray *friends;

@property (assign, nonatomic) dispatch_once_t configureOnceToken;

@end

@implementation OCTFriendsContainer
@synthesize friendsSort = _friendsSort;

#pragma mark -  Lifecycle

- (instancetype)initWithFriendsArray:(NSArray *)friends
{
    self = [super init];

    if (! self) {
        return nil;
    }

    self.friends = [NSMutableArray arrayWithArray:friends];

    return self;
}

#pragma mark -  OCTFriendsContainerProtocol

- (void)setFriendsSort:(OCTManagerFriendsSort)sort
{
    [self setFriendsSort:sort sendNotification:YES];
}

- (void)setFriendsSort:(OCTManagerFriendsSort)sort sendNotification:(BOOL)sendNotification
{
    _friendsSort = sort;

    [self.dataSource.friendsContainerGetSettingsStorage setObject:@(sort) forKey:kSortStorageKey];

    @synchronized(self.friends) {
        if (self.friends.count <= 1) {
            return;
        }

        [self.friends sortUsingComparator:[self comparatorForCurrentSort]];

        if (sendNotification) {
            NSRange range = NSMakeRange(0, self.friends.count);
            [self sendUpdateFriendsNotificationWithInsertedSet:nil
                                                    removedSet:nil
                                                    updatedSet:[NSIndexSet indexSetWithIndexesInRange:range]];
        }
    }
}

- (NSUInteger)friendsCount
{
    @synchronized(self.friends) {
        return self.friends.count;
    }
}

- (OCTFriend *)friendAtIndex:(NSUInteger)index
{
    @synchronized(self.friends) {
        if (index < self.friends.count) {
            return self.friends[index];
        }

        return nil;
    }
}

#pragma mark -  Public

- (void)configure
{
    dispatch_once(&_configureOnceToken, ^{
        NSNumber *sort = [self.dataSource.friendsContainerGetSettingsStorage objectForKey:kSortStorageKey];
        [self setFriendsSort:[sort unsignedIntegerValue] sendNotification:NO];
    });
}

- (void)addFriend:(OCTFriend *)friend
{
    NSParameterAssert(friend);

    if (! friend) {
        return;
    }

    @synchronized(self.friends) {
        NSUInteger index = [self.friends indexOfObject:friend];

        if (index != NSNotFound) {
            NSAssert(NO, @"Cannot add friend twice %@", friend);
            return;
        }

        index = [self.friends indexOfObject:friend
                              inSortedRange:NSMakeRange(0, self.friends.count)
                                    options:NSBinarySearchingInsertionIndex
                            usingComparator:[self comparatorForCurrentSort]];

        [self.friends insertObject:friend atIndex:index];

        [self sendUpdateFriendsNotificationWithInsertedSet:[NSIndexSet indexSetWithIndex:index]
                                                removedSet:nil
                                                updatedSet:nil];
    }
}

- (void)updateFriendWithFriendNumber:(OCTToxFriendNumber)friendNumber
                         updateBlock:(void (^)(OCTFriend *friendToUpdate))updateBlock
{
    NSParameterAssert(updateBlock);

    if (! updateBlock) {
        return;
    }

    @synchronized(self.friends) {
        NSUInteger index = NSNotFound;
        __block OCTFriend *friend = nil;

        index = [self.friends indexOfObjectPassingTest:^BOOL (OCTFriend *f, NSUInteger idx, BOOL *stop) {
            if (f.friendNumber == friendNumber) {
                friend = f;
                return YES;
            }

            return NO;
        }];

        if (index == NSNotFound) {
            NSAssert(NO, @"Friend to update not found");
            return;
        }

        updateBlock(friend);

        [self.friends removeObjectAtIndex:index];

        NSUInteger newIndex = [self.friends indexOfObject:friend
                                            inSortedRange:NSMakeRange(0, self.friends.count)
                                                  options:NSBinarySearchingInsertionIndex
                                          usingComparator:[self comparatorForCurrentSort]];

        [self.friends insertObject:friend atIndex:index];

        NSIndexSet *inserted, *removed, *updated;

        if (index == newIndex) {
            updated = [NSIndexSet indexSetWithIndex:index];
        }
        else {
            inserted = [NSIndexSet indexSetWithIndex:newIndex];
            removed = [NSIndexSet indexSetWithIndex:index];
        }

        [self sendUpdateFriendsNotificationWithInsertedSet:inserted
                                                removedSet:removed
                                                updatedSet:updated];
    }
}

- (void)removeFriend:(OCTFriend *)friend
{
    NSParameterAssert(friend);

    if (! friend) {
        return;
    }

    @synchronized(self.friends) {
        NSUInteger index = [self.friends indexOfObject:friend];

        if (index == NSNotFound) {
            NSAssert(NO, @"Cannot remove friend, friend not found");
            return;
        }

        [self.friends removeObjectAtIndex:index];

        [self sendUpdateFriendsNotificationWithInsertedSet:nil
                                                removedSet:[NSIndexSet indexSetWithIndex:index]
                                                updatedSet:nil];
    }
}

#pragma mark -  Private

- (void)sendUpdateFriendsNotificationWithInsertedSet:(NSIndexSet *)inserted
                                          removedSet:(NSIndexSet *)removed
                                          updatedSet:(NSIndexSet *)updated
{
    NSMutableDictionary *userInfo = [NSMutableDictionary new];

    if (inserted.count) {
        userInfo[kOCTFriendsContainerUpdateKeyInsertedSet] = inserted;
    }
    if (removed.count) {
        userInfo[kOCTFriendsContainerUpdateKeyRemovedSet] = removed;
    }
    if (updated.count) {
        userInfo[kOCTFriendsContainerUpdateKeyUpdatedSet] = updated;
    }

    if ([NSThread isMainThread]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kOCTFriendsContainerUpdateFriendsNotification
                                                            object:nil
                                                          userInfo:userInfo];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kOCTFriendsContainerUpdateFriendsNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    }
}

- (NSComparator)comparatorForCurrentSort
{
    NSComparator nameComparator = ^NSComparisonResult (OCTFriend *first, OCTFriend *second) {
        if (first.name && second.name) {
            return [first.name compare:second.name];
        }

        if (first.name) {
            return NSOrderedDescending;
        }
        if (second.name) {
            return NSOrderedAscending;
        }

        return [first.publicKey compare:second.publicKey];
    };

    switch(self.friendsSort) {
        case OCTManagerFriendsSortByName:
            return nameComparator;

        case OCTManagerFriendsSortByStatus:
            return ^NSComparisonResult (OCTFriend *first, OCTFriend *second) {
                if (first.connectionStatus  == OCTToxConnectionStatusNone &&
                    second.connectionStatus == OCTToxConnectionStatusNone)
                {
                    return nameComparator(first, second);
                }

                if (first.connectionStatus  == OCTToxConnectionStatusNone) {
                    return NSOrderedAscending;
                }
                if (second.connectionStatus  == OCTToxConnectionStatusNone) {
                    return NSOrderedDescending;
                }

                if (first.status == second.status) {
                    return nameComparator(first, second);
                }

                return (first.status > second.status) ? NSOrderedDescending : NSOrderedAscending;
            };
    }
}

@end
