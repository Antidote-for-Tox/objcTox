//
//  OCTSubmanagerFriendsTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "OCTSubmanagerFriends.h"
#import "OCTSubmanagerFriends+Private.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTFriendsContainer+Private.h"
#import "OCTFriendRequestContainer+Private.h"
#import "OCTTox.h"
#import "OCTDBManager.h"

static NSString *const kPublicKey = @"publicKey";
static NSString *const kName = @"name";
static NSString *const kStatusMessage = @"kStatusMessage";
static const OCTToxUserStatus kStatus = OCTToxUserStatusAway;
static const OCTToxConnectionStatus kConnectionStatus = OCTToxConnectionStatusUDP;
static NSDate *kLastSeenOnline;
static const BOOL kIsTyping = YES;

@interface OCTSubmanagerFriends(Tests)
@property (strong, nonatomic, readwrite) OCTFriendsContainer *friendsContainer;
@property (strong, nonatomic, readwrite) OCTFriendRequestContainer *friendRequestContainer;
- (OCTFriend *)createFriendWithFriendNumber:(OCTToxFriendNumber)friendNumber;
@end

@interface OCTSubmanagerFriendsTests : XCTestCase

@property (strong, nonatomic) OCTSubmanagerFriends *submanager;
@property (strong, nonatomic) id dataSource;

@end

@implementation OCTSubmanagerFriendsTests

- (void)setUp
{
    [super setUp];

    kLastSeenOnline = [NSDate date];

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));

    self.submanager = [OCTSubmanagerFriends new];
    self.submanager.dataSource = self.dataSource;
}

- (void)tearDown
{
    self.dataSource = nil;
    self.submanager = nil;

    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.submanager);
}

- (void)testConfigureFriends
{
    NSArray *numbersArray = @[@0, @1, @3, @5];
    NSArray *friendsArray = @[
        OCMClassMock([OCTFriend class]),
        OCMClassMock([OCTFriend class]),
        OCMClassMock([OCTFriend class]),
        OCMClassMock([OCTFriend class])];

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox friendsArray]).andReturn(numbersArray);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);

    id friendsContainer = OCMClassMock([OCTFriendsContainer class]);
    OCMStub([friendsContainer alloc]).andReturn(friendsContainer);
    OCMExpect([friendsContainer setDataSource:(id)self.submanager]);
    OCMExpect([friendsContainer configure]);
    OCMExpect([friendsContainer initWithFriendsArray:[OCMArg checkWithBlock:^BOOL (NSArray *array) {
        XCTAssertEqual(array.count, 4);
        XCTAssertEqual(array[0], friendsArray[0]);
        XCTAssertEqual(array[1], friendsArray[1]);
        XCTAssertEqual(array[2], friendsArray[2]);
        XCTAssertEqual(array[3], friendsArray[3]);

        return YES;
    }]]).andReturn(friendsContainer);

    OCTSubmanagerFriends *submanager = OCMPartialMock(self.submanager);
    OCMStub([submanager createFriendWithFriendNumber:0]).andReturn(friendsArray[0]);
    OCMStub([submanager createFriendWithFriendNumber:1]).andReturn(friendsArray[1]);
    OCMStub([submanager createFriendWithFriendNumber:3]).andReturn(friendsArray[2]);
    OCMStub([submanager createFriendWithFriendNumber:5]).andReturn(friendsArray[3]);

    [submanager configure];

    XCTAssertEqual(friendsContainer, submanager.friendsContainer);
    OCMVerifyAll(friendsContainer);

    [friendsContainer stopMocking];
}

- (void)testConfigureFriendRequests
{
    id friendRequests = @[
        OCMClassMock([OCTFriendRequest class]),
    ];

    id dbManager = OCMClassMock([OCTDBManager class]);
    OCMStub([dbManager friendRequests]).andReturn(friendRequests);

    OCMStub([self.dataSource managerGetDBManager]).andReturn(dbManager);

    id friendRequestContainer = OCMClassMock([OCTFriendRequestContainer class]);
    OCMStub([friendRequestContainer alloc]).andReturn(friendRequestContainer);
    OCMExpect([friendRequestContainer initWithFriendRequestsArray:[OCMArg checkWithBlock:^BOOL (NSArray *array) {
        XCTAssertEqual(array.count, 1);
        XCTAssertEqual(array[0], friendRequests[0]);

        return YES;
    }]]).andReturn(friendRequestContainer);

    [self.submanager configure];

    XCTAssertEqual(friendRequestContainer, self.submanager.friendRequestContainer);
    OCMVerifyAll(friendRequestContainer);
}

#pragma mark -  Public

- (void)testSendFriendRequestToAddress
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    [self stubMethodsForFriendCreationInTox:tox friendNumber:7];
    OCMStub([tox addFriendWithAddress:@"address" message:@"message" error:[OCMArg anyObjectRef]]).andReturn(7);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);
    OCMStub([self.dataSource managerSaveTox:[OCMArg anyObjectRef]]).andReturn(YES);

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:nil];
    BOOL result = [self.submanager sendFriendRequestToAddress:@"address" message:@"message" error:&error];

    XCTAssertTrue(result);
    XCTAssertEqual([self.submanager.friendsContainer friendsCount], 1);

    OCTFriend *friend = [self.submanager.friendsContainer friendAtIndex:0];
    [self verifyFriendWithStubbedConstants:friend friendNumber:7];

    OCMVerify([tox addFriendWithAddress:@"address" message:@"message" error:[OCMArg setTo:error]]);
    OCMVerify([self.dataSource managerSaveTox:[OCMArg setTo:error]]);
}

- (void)testSendFriendRequestToAddressFailure1
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox addFriendWithAddress:@"address" message:@"message" error:[OCMArg anyObjectRef]]).andReturn(kOCTToxFriendNumberFailure);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);

    BOOL result = [self.submanager sendFriendRequestToAddress:@"address" message:@"message" error:&error];

    XCTAssertFalse(result);
}

- (void)testSendFriendRequestToAddressFailure2
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    [self stubMethodsForFriendCreationInTox:tox friendNumber:7];
    OCMStub([tox addFriendWithAddress:@"address" message:@"message" error:[OCMArg anyObjectRef]]).andReturn(7);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);
    OCMStub([self.dataSource managerSaveTox:[OCMArg anyObjectRef]]).andReturn(NO);

    BOOL result = [self.submanager sendFriendRequestToAddress:@"address" message:@"message" error:&error];

    XCTAssertFalse(result);
}

- (void)testApproveFriendRequest
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    [self stubMethodsForFriendCreationInTox:tox friendNumber:7];
    OCMStub([tox addFriendWithNoRequestWithPublicKey:@"address" error:[OCMArg anyObjectRef]]).andReturn(7);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);
    OCMStub([self.dataSource managerSaveTox:[OCMArg anyObjectRef]]).andReturn(YES);

    id request = OCMClassMock([OCTFriendRequest class]);
    OCMStub([request publicKey]).andReturn(@"address");

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:nil];
    BOOL result = [self.submanager approveFriendRequest:request error:&error];

    XCTAssertTrue(result);
    XCTAssertEqual([self.submanager.friendsContainer friendsCount], 1);

    OCTFriend *friend = [self.submanager.friendsContainer friendAtIndex:0];
    [self verifyFriendWithStubbedConstants:friend friendNumber:7];

    OCMVerify([tox addFriendWithNoRequestWithPublicKey:@"address" error:[OCMArg setTo:error]]);
    OCMVerify([self.dataSource managerSaveTox:[OCMArg setTo:error]]);
}

- (void)testApproveFriendRequestFailure1
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox addFriendWithNoRequestWithPublicKey:@"address" error:[OCMArg anyObjectRef]]).andReturn(kOCTToxFriendNumberFailure);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);

    id request = OCMClassMock([OCTFriendRequest class]);
    OCMStub([request publicKey]).andReturn(@"address");

    BOOL result = [self.submanager approveFriendRequest:request error:&error];

    XCTAssertFalse(result);
}

- (void)testApproveFriendRequestFailure2
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    [self stubMethodsForFriendCreationInTox:tox friendNumber:7];
    OCMStub([tox addFriendWithNoRequestWithPublicKey:@"address" error:[OCMArg anyObjectRef]]).andReturn(7);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);
    OCMStub([self.dataSource managerSaveTox:[OCMArg anyObjectRef]]).andReturn(NO);

    id request = OCMClassMock([OCTFriendRequest class]);
    OCMStub([request publicKey]).andReturn(@"address");

    BOOL result = [self.submanager approveFriendRequest:request error:&error];

    XCTAssertFalse(result);
}

- (void)testRemoveFriendRequest
{
    id request = OCMClassMock([OCTFriendRequest class]);
    [self.submanager.friendRequestContainer addRequest:request];

    [self.submanager removeFriendRequest:request];

    XCTAssertEqual([self.submanager.friendRequestContainer requestsCount], 0);
}

- (void)testRemoveFriend
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox deleteFriendWithFriendNumber:7 error:[OCMArg anyObjectRef]]).andReturn(YES);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);
    OCMStub([self.dataSource managerSaveTox:[OCMArg anyObjectRef]]).andReturn(YES);

    id friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(7);

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:@[ friend ]];
    BOOL result = [self.submanager removeFriend:friend error:&error];

    XCTAssertTrue(result);
    XCTAssertEqual([self.submanager.friendsContainer friendsCount], 0);

    OCMVerify([tox deleteFriendWithFriendNumber:7 error:[OCMArg setTo:error]]);
    OCMVerify([self.dataSource managerSaveTox:[OCMArg setTo:error]]);
}

- (void)testRemoveFriendFailure1
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox deleteFriendWithFriendNumber:7 error:[OCMArg anyObjectRef]]).andReturn(NO);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);

    id friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(7);

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:@[ friend ]];
    BOOL result = [self.submanager removeFriend:friend error:&error];

    XCTAssertFalse(result);
    XCTAssertEqual([self.submanager.friendsContainer friendAtIndex:0], friend);
}

- (void)testRemoveFriendFailure2
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox deleteFriendWithFriendNumber:7 error:[OCMArg anyObjectRef]]).andReturn(YES);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);
    OCMStub([self.dataSource managerSaveTox:[OCMArg anyObjectRef]]).andReturn(NO);

    id friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(7);

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:@[ friend ]];
    BOOL result = [self.submanager removeFriend:friend error:&error];

    XCTAssertFalse(result);
    XCTAssertEqual([self.submanager.friendsContainer friendAtIndex:0], friend);
}

#pragma mark -  Private

- (void)testCreateFriendWithFriendNumber
{
    id tox = OCMClassMock([OCTTox class]);
    [self stubMethodsForFriendCreationInTox:tox friendNumber:5];

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);

    // wrong friend number
    OCTFriend *friend = [self.submanager createFriendWithFriendNumber:4];
    XCTAssertNil(friend);

    friend = [self.submanager createFriendWithFriendNumber:5];

    [self verifyFriendWithStubbedConstants:friend friendNumber:5];
}

- (void)stubMethodsForFriendCreationInTox:(id)tox friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCMStub([tox friendExistsWithFriendNumber:friendNumber]).andReturn(YES);
    OCMStub([tox publicKeyFromFriendNumber:friendNumber error:[OCMArg anyObjectRef]]).andReturn(kPublicKey);
    OCMStub([tox friendNameWithFriendNumber:friendNumber error:[OCMArg anyObjectRef]]).andReturn(kName);
    OCMStub([tox friendStatusMessageWithFriendNumber:friendNumber error:[OCMArg anyObjectRef]]).andReturn(kStatusMessage);
    OCMStub([tox friendStatusWithFriendNumber:friendNumber error:[OCMArg anyObjectRef]]).andReturn(kStatus);
    OCMStub([tox friendConnectionStatusWithFriendNumber:friendNumber error:[OCMArg anyObjectRef]]).andReturn(kConnectionStatus);
    OCMStub([tox friendGetLastOnlineWithFriendNumber:friendNumber error:[OCMArg anyObjectRef]]).andReturn(kLastSeenOnline);
    OCMStub([tox isFriendTypingWithFriendNumber:friendNumber error:[OCMArg anyObjectRef]]).andReturn(kIsTyping);
}

- (void)verifyFriendWithStubbedConstants:(OCTFriend *)friend friendNumber:(OCTToxFriendNumber)friendNumber
{
    XCTAssertEqual(friend.friendNumber, friendNumber);
    XCTAssertEqualObjects(friend.publicKey, kPublicKey);
    XCTAssertEqualObjects(friend.name, kName);
    XCTAssertEqualObjects(friend.statusMessage, kStatusMessage);
    XCTAssertEqual(friend.status, kStatus);
    XCTAssertEqual(friend.connectionStatus, kConnectionStatus);
    XCTAssertEqualObjects(friend.lastSeenOnline, kLastSeenOnline);
    XCTAssertEqual(friend.isTyping, kIsTyping);
}

@end
