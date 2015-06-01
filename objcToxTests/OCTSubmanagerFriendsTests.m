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
#import "OCTTox.h"
#import "OCTDBManager.h"
#import "OCTFriend+Private.h"
#import "OCTConverterFriend.h"

@interface OCTSubmanagerFriends (Tests)
@property (strong, nonatomic, readwrite) OCTFriendsContainer *friendsContainer;
@property (strong, nonatomic) OCTConverterFriend *converterFriend;
@end

@interface OCTSubmanagerFriendsTests : XCTestCase

@property (strong, nonatomic) OCTSubmanagerFriends *submanager;
@property (strong, nonatomic) id dataSource;

@end

@implementation OCTSubmanagerFriendsTests

- (void)setUp
{
    [super setUp];

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

    id converterFriend = OCMClassMock([OCTConverterFriend class]);
    OCMStub([converterFriend friendFromFriendNumber:0]).andReturn(friendsArray[0]);
    OCMStub([converterFriend friendFromFriendNumber:1]).andReturn(friendsArray[1]);
    OCMStub([converterFriend friendFromFriendNumber:3]).andReturn(friendsArray[2]);
    OCMStub([converterFriend friendFromFriendNumber:5]).andReturn(friendsArray[3]);
    self.submanager.converterFriend = converterFriend;

    [self.submanager configure];

    XCTAssertEqual(friendsContainer, self.submanager.friendsContainer);
    OCMVerifyAll(friendsContainer);

    [friendsContainer stopMocking];
}

#pragma mark -  Public

- (void)testSendFriendRequestToAddress
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox addFriendWithAddress:@"address" message:@"message" error:[OCMArg anyObjectRef]]).andReturn(7);

    id friend = OCMClassMock([OCTFriend class]);

    id converterFriend = OCMClassMock([OCTConverterFriend class]);
    OCMStub([converterFriend friendFromFriendNumber:7]).andReturn(friend);
    self.submanager.converterFriend = converterFriend;

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:nil];
    BOOL result = [self.submanager sendFriendRequestToAddress:@"address" message:@"message" error:&error];

    XCTAssertTrue(result);
    XCTAssertEqual([self.submanager.friendsContainer friendsCount], 1);

    OCTFriend *theFriend = [self.submanager.friendsContainer friendAtIndex:0];
    XCTAssertEqual(friend, theFriend);

    OCMVerify([tox addFriendWithAddress:@"address" message:@"message" error:[OCMArg setTo:error]]);
    OCMVerify([self.dataSource managerSaveTox]);
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

- (void)testApproveFriendRequest
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox addFriendWithNoRequestWithPublicKey:@"address" error:[OCMArg anyObjectRef]]).andReturn(7);

    id friend = OCMClassMock([OCTFriend class]);

    id converterFriend = OCMClassMock([OCTConverterFriend class]);
    OCMStub([converterFriend friendFromFriendNumber:7]).andReturn(friend);
    self.submanager.converterFriend = converterFriend;

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);

    id request = OCMClassMock([OCTFriendRequest class]);
    OCMStub([request publicKey]).andReturn(@"address");

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:nil];
    BOOL result = [self.submanager approveFriendRequest:request error:&error];

    XCTAssertTrue(result);
    XCTAssertEqual([self.submanager.friendsContainer friendsCount], 1);

    OCTFriend *theFriend = [self.submanager.friendsContainer friendAtIndex:0];
    XCTAssertEqual(friend, theFriend);

    OCMVerify([tox addFriendWithNoRequestWithPublicKey:@"address" error:[OCMArg setTo:error]]);
    OCMVerify([self.dataSource managerSaveTox]);
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

- (void)testRemoveFriendRequest
{
    id request = OCMClassMock([OCTFriendRequest class]);
    OCMStub([request publicKey]).andReturn(@"key");

    id dbManager = OCMClassMock([OCTDBManager class]);
    OCMStub([self.dataSource managerGetDBManager]).andReturn(dbManager);

    [self.submanager removeFriendRequest:request];

    OCMVerify([dbManager removeFriendRequestWithPublicKey:@"key"]);
}

- (void)testRemoveFriend
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox deleteFriendWithFriendNumber:7 error:[OCMArg anyObjectRef]]).andReturn(YES);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);

    OCTFriend *friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(7);

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:@[ friend ]];
    BOOL result = [self.submanager removeFriend:friend error:&error];

    XCTAssertTrue(result);
    XCTAssertEqual([self.submanager.friendsContainer friendsCount], 0);

    OCMVerify([tox deleteFriendWithFriendNumber:7 error:[OCMArg setTo:error]]);
    OCMVerify([self.dataSource managerSaveTox]);
}

- (void)testRemoveFriendFailure1
{
    NSError *error;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox deleteFriendWithFriendNumber:7 error:[OCMArg anyObjectRef]]).andReturn(NO);

    OCMStub([self.dataSource managerGetTox]).andReturn(tox);

    OCTFriend *friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(7);

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:@[ friend ]];
    BOOL result = [self.submanager removeFriend:friend error:&error];

    XCTAssertFalse(result);
    XCTAssertEqual([self.submanager.friendsContainer friendAtIndex:0], friend);
}

#pragma mark -  OCTToxDelegate

- (void)testFriendRequestWithMessage
{
    id dbManager = OCMClassMock([OCTDBManager class]);
    OCMStub([self.dataSource managerGetDBManager]).andReturn(dbManager);

    NSDate *before = [NSDate date];

    OCMExpect([dbManager addFriendRequest:[OCMArg checkWithBlock:^BOOL (OCTDBFriendRequest *request) {
        NSDate *after = [NSDate date];

        return
        [request.message isEqualToString:@"message"] &&
        [request.publicKey isEqualToString:@"publicKey"];
        (request.dateInterval >= [before timeIntervalSince1970]) &&
        (request.dateInterval <= [after timeIntervalSince1970]);
    }]]);

    [self.submanager tox:nil friendRequestWithMessage:@"message" publicKey:@"publicKey"];

    OCMVerifyAll(dbManager);
}

- (void)testToxFriendNameUpdate
{
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 7;

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:@[ friend ]];
    [self.submanager tox:nil friendNameUpdate:@"name" friendNumber:7];

    XCTAssertEqualObjects(friend.name, @"name");
    OCMVerify([self.dataSource managerSaveTox]);
}

- (void)testToxFriendStatusMessageUpdate
{
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 7;

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:@[ friend ]];
    [self.submanager tox:nil friendStatusMessageUpdate:@"statusMessage" friendNumber:7];

    XCTAssertEqualObjects(friend.statusMessage, @"statusMessage");
    OCMVerify([self.dataSource managerSaveTox]);
}

- (void)testToxFriendStatusUpdate
{
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 7;

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:@[ friend ]];
    [self.submanager tox:nil friendStatusUpdate:OCTToxUserStatusBusy friendNumber:7];

    XCTAssertEqual(friend.status, OCTToxUserStatusBusy);
    OCMVerify([self.dataSource managerSaveTox]);
}

- (void)testToxFriendIsTypingUpdate
{
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 7;

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:@[ friend ]];
    [self.submanager tox:nil friendIsTypingUpdate:YES friendNumber:7];

    XCTAssertEqual(friend.isTyping, YES);
}

- (void)testToxFriendConnectionStatusUpdate
{
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 7;

    self.submanager.friendsContainer = [[OCTFriendsContainer alloc] initWithFriendsArray:@[ friend ]];
    [self.submanager tox:nil friendConnectionStatusChanged:OCTToxConnectionStatusUDP friendNumber:7];

    XCTAssertEqual(friend.connectionStatus, OCTToxConnectionStatusUDP);
}

@end
