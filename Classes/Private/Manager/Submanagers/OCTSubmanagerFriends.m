//
//  OCTSubmanagerFriends.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerFriends.h"
#import "OCTSubmanagerFriends+Private.h"
#import "OCTFriendsContainer.h"
#import "OCTFriendsContainer+Private.h"
#import "OCTTox.h"

@interface OCTSubmanagerFriends() <OCTFriendsContainerDataSource>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@property (strong, nonatomic, readwrite) OCTFriendsContainer *friendsContainer;
@property (strong, nonatomic, readwrite) OCTFriendRequestContainer *friendRequestContainer;

@end

@implementation OCTSubmanagerFriends

- (instancetype)init
{
    self = [super init];

    if (! self) {
        return nil;
    }

    return self;
}

#pragma mark -  Public

- (void)configure
{
    OCTTox *tox = [self.dataSource managerGetTox];

    NSMutableArray *array = [NSMutableArray new];
    for (NSNumber *friendNumber in [tox friendsArray]) {
        OCTFriend *friend = [self createFriendWithFriendNumber:friendNumber.unsignedIntValue];

        if (friend) {
            [array addObject:friend];
        }
    }

    self.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:[array copy]];
    self.friendsContainer.dataSource = self;
    [self.friendsContainer configure];
}

#pragma mark -  OCTFriendsContainerDataSource

- (id<OCTSettingsStorageProtocol>)friendsContainerGetSettingsStorage
{
    return [self.dataSource managerGetSettingsStorage];
}

#pragma mark -  Supporting

- (OCTFriend *)createFriendWithFriendNumber:(OCTToxFriendNumber)friendNumber
{
    return nil;
}

@end
