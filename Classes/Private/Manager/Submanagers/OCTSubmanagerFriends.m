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
#import "OCTDBManager.h"

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

    NSMutableArray *friendsArray = [NSMutableArray new];
    for (NSNumber *friendNumber in [tox friendsArray]) {
        OCTFriend *friend = [self createFriendWithFriendNumber:friendNumber.unsignedIntValue];

        if (friend) {
            [friendsArray addObject:friend];
        }
    }

    self.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:[friendsArray copy]];
    self.friendsContainer.dataSource = self;
    [self.friendsContainer configure];

    NSArray *friendRequestsArray = [[self.dataSource managerGetDBManager] friendRequests];
    self.friendRequestContainer = [[OCTFriendRequestContainer alloc] initWithFriendRequestsArray:friendRequestsArray];
}

#pragma mark -  OCTFriendsContainerDataSource

- (id<OCTSettingsStorageProtocol>)friendsContainerGetSettingsStorage
{
    return [self.dataSource managerGetSettingsStorage];
}

#pragma mark -  OCTToxDelegate

- (void)tox:(OCTTox *)tox friendRequestWithMessage:(NSString *)message publicKey:(NSString *)publicKey
{
    OCTFriendRequest *request = [OCTFriendRequest new];
    request.message = message;
    request.publicKey = publicKey;

    [self.friendRequestContainer addRequest:request];
}

- (void)tox:(OCTTox *)tox friendNameUpdate:(NSString *)name friendNumber:(OCTToxFriendNumber)friendNumber
{
    [self.friendsContainer updateFriendWithFriendNumber:friendNumber updateBlock:^(OCTFriend *friend) {
        friend.name = name;
    }];
}

- (void)tox:(OCTTox *)tox friendStatusMessageUpdate:(NSString *)statusMessage friendNumber:(OCTToxFriendNumber)friendNumber
{
    [self.friendsContainer updateFriendWithFriendNumber:friendNumber updateBlock:^(OCTFriend *friend) {
        friend.statusMessage = statusMessage;
    }];
}

- (void)tox:(OCTTox *)tox friendStatusUpdate:(OCTToxUserStatus)status friendNumber:(OCTToxFriendNumber)friendNumber
{
    [self.friendsContainer updateFriendWithFriendNumber:friendNumber updateBlock:^(OCTFriend *friend) {
        friend.status = status;
    }];
}

- (void)tox:(OCTTox *)tox friendIsTypingUpdate:(BOOL)isTyping friendNumber:(OCTToxFriendNumber)friendNumber
{
    [self.friendsContainer updateFriendWithFriendNumber:friendNumber updateBlock:^(OCTFriend *friend) {
        friend.isTyping = isTyping;
    }];
}

- (void)tox:(OCTTox *)tox friendConnectionStatusChanged:(OCTToxConnectionStatus)status friendNumber:(OCTToxFriendNumber)friendNumber
{
    [self.friendsContainer updateFriendWithFriendNumber:friendNumber updateBlock:^(OCTFriend *friend) {
        friend.connectionStatus = status;
    }];
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
