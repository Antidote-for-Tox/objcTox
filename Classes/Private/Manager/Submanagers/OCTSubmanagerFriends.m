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
#import "OCTFriendRequestContainer+Private.h"
#import "OCTTox.h"
#import "OCTFriend+Private.h"

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

- (BOOL)sendFriendRequestToAddress:(NSString *)address message:(NSString *)message error:(NSError **)error
{
    NSParameterAssert(address);
    NSParameterAssert(message);

    OCTTox *tox = [self.dataSource managerGetTox];

    OCTToxFriendNumber friendNumber = [tox addFriendWithAddress:address message:message error:error];

    if (friendNumber == kOCTToxFriendNumberFailure) {
        return NO;
    }

    if (! [self.dataSource managerSaveTox:error]) {
        return NO;
    }

    OCTFriend *friend = [self createFriendWithFriendNumber:friendNumber];
    [self.friendsContainer addFriend:friend];

    return YES;
}

- (BOOL)approveFriendRequest:(OCTFriendRequest *)friendRequest error:(NSError **)error
{
    NSParameterAssert(friendRequest);

    OCTTox *tox = [self.dataSource managerGetTox];

    OCTToxFriendNumber friendNumber = [tox addFriendWithNoRequestWithPublicKey:friendRequest.publicKey error:error];

    if (friendNumber == kOCTToxFriendNumberFailure) {
        return NO;
    }

    if (! [self.dataSource managerSaveTox:error]) {
        return NO;
    }

    OCTFriend *friend = [self createFriendWithFriendNumber:friendNumber];
    [self.friendsContainer addFriend:friend];

    return YES;
}

- (BOOL)removeFriendRequest:(OCTFriendRequest *)friendRequest
{
    NSParameterAssert(friendRequest);

    [self.friendRequestContainer removeRequest:friendRequest];

    return YES;
}

- (BOOL)removeFriend:(OCTFriend *)friend error:(NSError **)error
{
    NSParameterAssert(friend);

    OCTTox *tox = [self.dataSource managerGetTox];

    BOOL result = [tox deleteFriendWithFriendNumber:friend.friendNumber error:error];

    if (! result) {
        return NO;
    }

    if (! [self.dataSource managerSaveTox:error]) {
        return NO;
    }

    [self.friendsContainer removeFriend:friend];

    return YES;
}

#pragma mark -  Private category

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

#pragma mark -  Private

- (OCTFriend *)createFriendWithFriendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTTox *tox = [self.dataSource managerGetTox];

    if (! [tox friendExistsWithFriendNumber:friendNumber]) {
        return nil;
    }

    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = friendNumber;
    friend.publicKey = [tox publicKeyFromFriendNumber:friendNumber error:nil];
    friend.name = [tox friendNameWithFriendNumber:friendNumber error:nil];
    friend.statusMessage = [tox friendStatusMessageWithFriendNumber:friendNumber error:nil];
    friend.status = [tox friendStatusWithFriendNumber:friendNumber error:nil];
    friend.connectionStatus = [tox friendConnectionStatusWithFriendNumber:friendNumber error:nil];
    friend.lastSeenOnline = [tox friendGetLastOnlineWithFriendNumber:friendNumber error:nil];
    friend.isTyping = [tox isFriendTypingWithFriendNumber:friendNumber error:nil];

    return friend;
}

@end
