//
//  OCTSubmanagerFriends.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerFriends.h"
#import "OCTSubmanagerFriends+Private.h"
#import "OCTTox.h"
#import "OCTFriend.h"
#import "OCTFriendRequest.h"
#import "OCTRealmManager.h"

@interface OCTSubmanagerFriends ()

@end

@implementation OCTSubmanagerFriends
@synthesize dataSource = _dataSource;

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

    [self.dataSource managerSaveTox];

    return [self createFriendWithFriendNumber:friendNumber error:error];
}

- (BOOL)approveFriendRequest:(OCTFriendRequest *)friendRequest error:(NSError **)error
{
    NSParameterAssert(friendRequest);

    OCTTox *tox = [self.dataSource managerGetTox];

    OCTToxFriendNumber friendNumber = [tox addFriendWithNoRequestWithPublicKey:friendRequest.publicKey error:error];

    if (friendNumber == kOCTToxFriendNumberFailure) {
        return NO;
    }

    [self.dataSource managerSaveTox];

    [[self.dataSource managerGetRealmManager] deleteObject:friendRequest];

    return [self createFriendWithFriendNumber:friendNumber error:error];
}

- (void)removeFriendRequest:(OCTFriendRequest *)friendRequest
{
    NSParameterAssert(friendRequest);

    [[self.dataSource managerGetRealmManager] deleteObject:friendRequest];
}

- (BOOL)removeFriend:(OCTFriend *)friend error:(NSError **)error
{
    NSParameterAssert(friend);

    OCTTox *tox = [self.dataSource managerGetTox];

    if (! [tox deleteFriendWithFriendNumber:friend.friendNumber error:error]) {
        return NO;
    }

    [self.dataSource managerSaveTox];

    [[self.dataSource managerGetRealmManager] deleteObject:friend];

    return YES;
}

#pragma mark -  Private category

- (void)configure
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    [realmManager updateObjectsWithClass:[OCTFriend class] predicate:nil updateBlock:^(OCTFriend *friend) {
        friend.status = OCTToxUserStatusNone;
        friend.isConnected = NO;
        friend.connectionStatus = OCTToxConnectionStatusNone;
        friend.isTyping = NO;
        NSDate *dateOffline = [[self.dataSource managerGetTox] friendGetLastOnlineWithFriendNumber:friend.friendNumber error:nil];
        friend.lastSeenOnlineInterval = [dateOffline timeIntervalSince1970];
    }];

    RLMResults *allFriends = [realmManager objectsWithClass:[OCTFriend class] predicate:nil];

    for (NSNumber *friendNumber in [[self.dataSource managerGetTox] friendsArray]) {
        OCTToxFriendNumber number = [friendNumber intValue];

        BOOL found = NO;

        for (OCTFriend *friend in allFriends) {
            if (friend.friendNumber == number) {
                found = YES;
                break;
            }
        }

        if (! found) {
            // it seems that friend is in Tox but isn't in Realm. Let's add it.
            [self createFriendWithFriendNumber:number error:nil];
        }
    }
}

#pragma mark -  OCTToxDelegate

- (void)tox:(OCTTox *)tox friendRequestWithMessage:(NSString *)message publicKey:(NSString *)publicKey
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"publicKey == %@", publicKey];
    RLMResults *results = [realmManager objectsWithClass:[OCTFriendRequest class] predicate:predicate];
    if (results.count > 0) {
        // friendRequest already exists
        return;
    }

    results = [realmManager objectsWithClass:[OCTFriend class] predicate:predicate];
    if (results.count > 0) {
        // friend with such publicKey already exists
        return;
    }

    OCTFriendRequest *request = [OCTFriendRequest new];
    request.publicKey = publicKey;
    request.message = message;
    request.dateInterval = [[NSDate date] timeIntervalSince1970];

    [realmManager addObject:request];
}

- (void)tox:(OCTTox *)tox friendNameUpdate:(NSString *)name friendNumber:(OCTToxFriendNumber)friendNumber
{
    [self.dataSource managerSaveTox];

    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    [realmManager updateObject:[realmManager friendWithFriendNumber:friendNumber] withBlock:^(OCTFriend *theFriend) {
        theFriend.name = name;

        if (name.length && [theFriend.nickname isEqualToString:theFriend.publicKey]) {
            theFriend.nickname = name;
        }
    }];
}

- (void)tox:(OCTTox *)tox friendStatusMessageUpdate:(NSString *)statusMessage friendNumber:(OCTToxFriendNumber)friendNumber
{
    [self.dataSource managerSaveTox];

    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    [realmManager updateObject:[realmManager friendWithFriendNumber:friendNumber] withBlock:^(OCTFriend *theFriend) {
        theFriend.statusMessage = statusMessage;
    }];
}

- (void)tox:(OCTTox *)tox friendStatusUpdate:(OCTToxUserStatus)status friendNumber:(OCTToxFriendNumber)friendNumber
{
    [self.dataSource managerSaveTox];

    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    [realmManager updateObject:[realmManager friendWithFriendNumber:friendNumber] withBlock:^(OCTFriend *theFriend) {
        theFriend.status = status;
    }];
}

- (void)tox:(OCTTox *)tox friendIsTypingUpdate:(BOOL)isTyping friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    [realmManager updateObject:[realmManager friendWithFriendNumber:friendNumber] withBlock:^(OCTFriend *theFriend) {
        theFriend.isTyping = isTyping;
    }];
}

- (void)tox:(OCTTox *)tox friendConnectionStatusChanged:(OCTToxConnectionStatus)status friendNumber:(OCTToxFriendNumber)friendNumber
{
    [self.dataSource managerSaveTox];

    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];
    OCTFriend *friend = [realmManager friendWithFriendNumber:friendNumber];

    [realmManager updateObject:friend withBlock:^(OCTFriend *theFriend) {
        theFriend.isConnected = (status != OCTToxConnectionStatusNone);
        theFriend.connectionStatus = status;

        if (! theFriend.isConnected) {
            NSDate *dateOffline = [tox friendGetLastOnlineWithFriendNumber:friendNumber error:nil];
            NSTimeInterval timeSince = [dateOffline timeIntervalSince1970];
            theFriend.lastSeenOnlineInterval = timeSince;
        }
    }];

    [[self.dataSource managerGetNotificationCenter] postNotificationName:kOCTFriendConnectionStatusChangeNotification object:friend];
}

#pragma mark -  Private

- (BOOL)createFriendWithFriendNumber:(OCTToxFriendNumber)friendNumber error:(NSError **)userError
{
    OCTTox *tox = [self.dataSource managerGetTox];
    NSError *error;

    OCTFriend *friend = [OCTFriend new];

    friend.friendNumber = friendNumber;

    friend.publicKey = [tox publicKeyFromFriendNumber:friendNumber error:&error];
    if ([self checkForError:error andAssignTo:userError]) {
        return NO;
    }

    friend.name = [tox friendNameWithFriendNumber:friendNumber error:&error];
    if ([self checkForError:error andAssignTo:userError]) {
        return NO;
    }

    friend.statusMessage = [tox friendStatusMessageWithFriendNumber:friendNumber error:&error];
    if ([self checkForError:error andAssignTo:userError]) {
        return NO;
    }

    friend.status = [tox friendStatusWithFriendNumber:friendNumber error:&error];
    if ([self checkForError:error andAssignTo:userError]) {
        return NO;
    }

    friend.connectionStatus = [tox friendConnectionStatusWithFriendNumber:friendNumber error:&error];
    if ([self checkForError:error andAssignTo:userError]) {
        return NO;
    }

    NSDate *lastSeenOnline = [tox friendGetLastOnlineWithFriendNumber:friendNumber error:&error];
    friend.lastSeenOnlineInterval = [lastSeenOnline timeIntervalSince1970];
    if ([self checkForError:error andAssignTo:userError]) {
        return NO;
    }

    friend.isTyping = [tox isFriendTypingWithFriendNumber:friendNumber error:&error];
    if ([self checkForError:error andAssignTo:userError]) {
        return NO;
    }

    friend.isConnected = (friend.connectionStatus != OCTToxConnectionStatusNone);
    friend.nickname = friend.name.length ? friend.name : friend.publicKey;

    [[self.dataSource managerGetRealmManager] addObject:friend];

    return YES;
}

- (BOOL)checkForError:(NSError *)toCheck andAssignTo:(NSError **)toAssign
{
    if (! toCheck) {
        return NO;
    }

    if (toAssign) {
        *toAssign = toCheck;
    }

    return YES;
}

@end
