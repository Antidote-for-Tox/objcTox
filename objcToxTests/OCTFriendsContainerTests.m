//
//  OCTFriendsContainerTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 06.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTFriendsContainer+Private.h"
#import "OCTFriend.h"

static NSString *const kSortStorageKey = @"OCTFriendsContainer.sortStorageKey";

@interface OCTFriendsContainer(Tests)

@property (strong, nonatomic) NSMutableArray *friends;
- (NSComparator)comparatorForCurrentSort;

@end

@interface OCTFriend(Tests)
@property (assign, nonatomic, readwrite) OCTToxFriendNumber friendNumber;
@property (copy, nonatomic, readwrite) NSString *name;
@end

@interface OCTFriendsContainerTests : XCTestCase

@property (strong, nonatomic) OCTFriendsContainer *container;

@end

@implementation OCTFriendsContainerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.container = [[OCTFriendsContainer alloc] initWithFriendsArray:nil];
    self.container.friendsSort = OCTFriendsSortByName;
}

- (void)tearDown
{
    self.container = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark -  Test public methods

- (void)testSetFriendsSort
{
    id friendNoneNoneB = OCMClassMock([OCTFriend class]);
    OCMStub([friendNoneNoneB status]).andReturn(OCTToxUserStatusNone);
    OCMStub([friendNoneNoneB connectionStatus]).andReturn(OCTToxConnectionStatusNone);
    OCMStub([friendNoneNoneB name]).andReturn(@"B");
    [self.container addFriend:friendNoneNoneB];

    id friendNoneNoneD = OCMClassMock([OCTFriend class]);
    OCMStub([friendNoneNoneD status]).andReturn(OCTToxUserStatusNone);
    OCMStub([friendNoneNoneD connectionStatus]).andReturn(OCTToxConnectionStatusNone);
    OCMStub([friendNoneNoneD name]).andReturn(@"D");
    [self.container addFriend:friendNoneNoneD];

    id friendNoneTcpI = OCMClassMock([OCTFriend class]);
    OCMStub([friendNoneTcpI status]).andReturn(OCTToxUserStatusNone);
    OCMStub([friendNoneTcpI connectionStatus]).andReturn(OCTToxConnectionStatusTCP);
    OCMStub([friendNoneTcpI name]).andReturn(@"I");
    [self.container addFriend:friendNoneTcpI];

    id friendAwayTcpF = OCMClassMock([OCTFriend class]);
    OCMStub([friendAwayTcpF status]).andReturn(OCTToxUserStatusAway);
    OCMStub([friendAwayTcpF connectionStatus]).andReturn(OCTToxConnectionStatusTCP);
    OCMStub([friendAwayTcpF name]).andReturn(@"F");
    [self.container addFriend:friendAwayTcpF];

    id friendAwayTcpH = OCMClassMock([OCTFriend class]);
    OCMStub([friendAwayTcpH status]).andReturn(OCTToxUserStatusAway);
    OCMStub([friendAwayTcpH connectionStatus]).andReturn(OCTToxConnectionStatusTCP);
    OCMStub([friendAwayTcpH name]).andReturn(@"H");
    [self.container addFriend:friendAwayTcpH];

    id friendBusyTcpG = OCMClassMock([OCTFriend class]);
    OCMStub([friendBusyTcpG status]).andReturn(OCTToxUserStatusBusy);
    OCMStub([friendBusyTcpG connectionStatus]).andReturn(OCTToxConnectionStatusTCP);
    OCMStub([friendBusyTcpG name]).andReturn(@"G");
    [self.container addFriend:friendBusyTcpG];

    id friendBusyTcpE = OCMClassMock([OCTFriend class]);
    OCMStub([friendBusyTcpE status]).andReturn(OCTToxUserStatusBusy);
    OCMStub([friendBusyTcpE connectionStatus]).andReturn(OCTToxConnectionStatusTCP);
    OCMStub([friendBusyTcpE name]).andReturn(@"E");
    [self.container addFriend:friendBusyTcpE];

    id friendBusyUdpC = OCMClassMock([OCTFriend class]);
    OCMStub([friendBusyUdpC status]).andReturn(OCTToxUserStatusBusy);
    OCMStub([friendBusyUdpC connectionStatus]).andReturn(OCTToxConnectionStatusUDP);
    OCMStub([friendBusyUdpC name]).andReturn(@"C");
    [self.container addFriend:friendBusyUdpC];

    id friendBusyUdpA = OCMClassMock([OCTFriend class]);
    OCMStub([friendBusyUdpA status]).andReturn(OCTToxUserStatusBusy);
    OCMStub([friendBusyUdpA connectionStatus]).andReturn(OCTToxConnectionStatusUDP);
    OCMStub([friendBusyUdpA name]).andReturn(@"A");
    [self.container addFriend:friendBusyUdpA];

    self.container.friendsSort = OCTFriendsSortByName;

    XCTAssertEqual([self.container friendAtIndex:0], friendBusyUdpA);
    XCTAssertEqual([self.container friendAtIndex:1], friendNoneNoneB);
    XCTAssertEqual([self.container friendAtIndex:2], friendBusyUdpC);
    XCTAssertEqual([self.container friendAtIndex:3], friendNoneNoneD);
    XCTAssertEqual([self.container friendAtIndex:4], friendBusyTcpE);
    XCTAssertEqual([self.container friendAtIndex:5], friendAwayTcpF);
    XCTAssertEqual([self.container friendAtIndex:6], friendBusyTcpG);
    XCTAssertEqual([self.container friendAtIndex:7], friendAwayTcpH);
    XCTAssertEqual([self.container friendAtIndex:8], friendNoneTcpI);

    self.container.friendsSort = OCTFriendsSortByStatus;

    OCTFriend *friend;

    friend = [self.container friendAtIndex:0];
    XCTAssertEqual(friend, friendNoneTcpI, @"Expected I, received %@", friend.name);
    friend = [self.container friendAtIndex:1];
    XCTAssertEqual(friend, friendAwayTcpF, @"Expected F, received %@", friend.name);
    friend = [self.container friendAtIndex:2];
    XCTAssertEqual(friend, friendAwayTcpH, @"Expected H, received %@", friend.name);
    friend = [self.container friendAtIndex:3];
    XCTAssertEqual(friend, friendBusyUdpA, @"Expected A, received %@", friend.name);
    friend = [self.container friendAtIndex:4];
    XCTAssertEqual(friend, friendBusyUdpC, @"Expected C, received %@", friend.name);
    friend = [self.container friendAtIndex:5];
    XCTAssertEqual(friend, friendBusyTcpE, @"Expected E, received %@", friend.name);
    friend = [self.container friendAtIndex:6];
    XCTAssertEqual(friend, friendBusyTcpG, @"Expected G, received %@", friend.name);
    friend = [self.container friendAtIndex:7];
    XCTAssertEqual(friend, friendNoneNoneB, @"Expected B, received %@", friend.name);
    friend = [self.container friendAtIndex:8];
    XCTAssertEqual(friend, friendNoneNoneD, @"Expected D, received %@", friend.name);
}

- (void)testFriendsCount
{
    XCTAssertEqual([self.container friendsCount], 0);

    [self.container addFriend:OCMClassMock([OCTFriend class])];
    [self.container addFriend:OCMClassMock([OCTFriend class])];

    XCTAssertEqual([self.container friendsCount], 2);
}

- (void)testFriendAtIndex
{
    id friend0 = OCMClassMock([OCTFriend class]);
    OCMStub([friend0 name]).andReturn(@"friend0");

    id friend1 = OCMClassMock([OCTFriend class]);
    OCMStub([friend1 name]).andReturn(@"friend1");

    [self.container addFriend:friend0];
    [self.container addFriend:friend1];

    XCTAssertEqual([self.container friendAtIndex:0], friend0);
    XCTAssertEqual([self.container friendAtIndex:1], friend1);
    XCTAssertNil([self.container friendAtIndex:2]);
}

- (void)testUpdateFriendsNotificationForFriendSort
{
    id friend0 = OCMClassMock([OCTFriend class]);
    OCMStub([friend0 name]).andReturn(@"friend0");

    id friend1 = OCMClassMock([OCTFriend class]);
    OCMStub([friend1 name]).andReturn(@"friend1");

    [self.container addFriend:friend0];
    [self.container addFriend:friend1];

    BOOL (^checkBlock)(NSDictionary *) = ^BOOL (NSDictionary *userInfo) {
        XCTAssertTrue([userInfo isKindOfClass:[NSDictionary class]]);
        XCTAssertEqual(userInfo.count, 1);

        NSIndexSet *set = userInfo[kOCTFriendsContainerUpdateKeyUpdatedSet];
        XCTAssertEqual(set.count, 2);
        XCTAssertTrue([set containsIndex:0]);
        XCTAssertTrue([set containsIndex:1]);

        return YES;
    };

    id center = OCMClassMock([NSNotificationCenter class]);
    OCMStub([center defaultCenter]).andReturn(center);
    OCMExpect([center postNotificationName:kOCTFriendsContainerUpdateFriendsNotification
                                    object:nil
                                  userInfo:[OCMArg checkWithBlock:checkBlock]]);

    self.container.friendsSort = OCTFriendsSortByStatus;

    OCMVerifyAll(center);
}

- (void)testUpdateFriendsNotificationForAddFriend
{
    id friend0 = OCMClassMock([OCTFriend class]);
    OCMStub([friend0 name]).andReturn(@"friend0");

    [self.container addFriend:friend0];

    BOOL (^checkBlock)(NSDictionary *) = ^BOOL (NSDictionary *userInfo) {
        XCTAssertTrue([userInfo isKindOfClass:[NSDictionary class]]);
        XCTAssertEqual(userInfo.count, 1);

        NSIndexSet *set = userInfo[kOCTFriendsContainerUpdateKeyInsertedSet];
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:1]);

        return YES;
    };

    id center = OCMClassMock([NSNotificationCenter class]);
    OCMStub([center defaultCenter]).andReturn(center);
    OCMExpect([center postNotificationName:kOCTFriendsContainerUpdateFriendsNotification
                                    object:nil
                                  userInfo:[OCMArg checkWithBlock:checkBlock]]);

    id friend1 = OCMClassMock([OCTFriend class]);
    OCMStub([friend1 name]).andReturn(@"friend1");
    [self.container addFriend:friend1];

    OCMVerifyAll(center);
}

- (void)testUpdateFriendsNotificationForRemoveFriend
{
    id friend0 = OCMClassMock([OCTFriend class]);
    OCMStub([friend0 name]).andReturn(@"friend0");

    id friend1 = OCMClassMock([OCTFriend class]);
    OCMStub([friend1 name]).andReturn(@"friend1");

    [self.container addFriend:friend0];
    [self.container addFriend:friend1];

    BOOL (^checkBlock)(NSDictionary *) = ^BOOL (NSDictionary *userInfo) {
        XCTAssertTrue([userInfo isKindOfClass:[NSDictionary class]]);
        XCTAssertEqual(userInfo.count, 1);

        NSIndexSet *set = userInfo[kOCTFriendsContainerUpdateKeyRemovedSet];
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:1]);

        return YES;
    };

    id center = OCMClassMock([NSNotificationCenter class]);
    OCMStub([center defaultCenter]).andReturn(center);
    OCMExpect([center postNotificationName:kOCTFriendsContainerUpdateFriendsNotification
                                    object:nil
                                  userInfo:[OCMArg checkWithBlock:checkBlock]]);

    [self.container removeFriend:friend1];

    OCMVerifyAll(center);
}

- (void)testUpdateFriendsNotificationForUpdateFriend
{
    OCTFriend *friend0 = [OCTFriend new];
    friend0.name = @"friend0";
    friend0.friendNumber = 0;

    id friend1 = OCMClassMock([OCTFriend class]);
    OCMStub([friend1 name]).andReturn(@"friend1");
    OCMStub([friend1 friendNumber]).andReturn(1);

    [self.container addFriend:friend0];
    [self.container addFriend:friend1];

    BOOL (^checkBlock)(NSDictionary *) = ^BOOL (NSDictionary *userInfo) {
        XCTAssertTrue([userInfo isKindOfClass:[NSDictionary class]]);
        XCTAssertEqual(userInfo.count, 2);

        NSIndexSet *set = userInfo[kOCTFriendsContainerUpdateKeyRemovedSet];
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:0]);

        set = userInfo[kOCTFriendsContainerUpdateKeyInsertedSet];
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:1]);

        return YES;
    };

    id center = OCMClassMock([NSNotificationCenter class]);
    OCMStub([center defaultCenter]).andReturn(center);
    OCMExpect([center postNotificationName:kOCTFriendsContainerUpdateFriendsNotification
                                    object:nil
                                  userInfo:[OCMArg checkWithBlock:checkBlock]]);

    [self.container updateFriendWithFriendNumber:0 updateBlock:^(OCTFriend *f) {
        f.name = @"friend2";
    }];

    OCMVerifyAll(center);
}

#pragma mark -  Test private methods

- (void)testInitWithFriendsArray
{
    id friend = OCMClassMock([OCTFriend class]);

    OCTFriendsContainer *container = [[OCTFriendsContainer alloc] initWithFriendsArray:@[ friend ]];

    XCTAssertTrue(container.friends.count == 1);

    id theFriend = [container.friends lastObject];
    XCTAssertEqual(friend, theFriend);
}

- (void)testConfigure1
{
    id storage = OCMProtocolMock(@protocol(OCTSettingsStorageProtocol));
    OCMStub([storage objectForKey:[OCMArg isEqual:kSortStorageKey]]).andReturn(@(OCTFriendsSortByName));

    id dataSource = OCMProtocolMock(@protocol(OCTFriendsContainerDataSource));
    OCMStub([dataSource friendsContainerGetSettingsStorage]).andReturn(storage);

    self.container.dataSource = dataSource;
    [self.container configure];

    XCTAssertEqual(self.container.friendsSort, OCTFriendsSortByName);
}

- (void)testConfigure2
{
    id storage = OCMProtocolMock(@protocol(OCTSettingsStorageProtocol));
    OCMStub([storage objectForKey:[OCMArg isEqual:kSortStorageKey]]).andReturn(@(OCTFriendsSortByStatus));

    id dataSource = OCMProtocolMock(@protocol(OCTFriendsContainerDataSource));
    OCMStub([dataSource friendsContainerGetSettingsStorage]).andReturn(storage);

    self.container.dataSource = dataSource;
    [self.container configure];

    XCTAssertEqual(self.container.friendsSort, OCTFriendsSortByStatus);
}

- (void)testAddFriend
{
    id friend = OCMClassMock([OCTFriend class]);

    [self.container addFriend:friend];

    XCTAssertTrue(self.container.friends.count == 1);

    id theFriend = [self.container.friends lastObject];
    XCTAssertEqual(friend, theFriend);

    XCTAssertThrowsSpecificNamed([self.container addFriend:nil], NSException, NSInternalInconsistencyException);
    // trying to add save friend twice
    XCTAssertThrowsSpecificNamed([self.container addFriend:friend], NSException, NSInternalInconsistencyException);
}

- (void)testUpdateFriend
{
    OCTToxFriendNumber friendNumber = 1;

    id friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(friendNumber);

    [self.container addFriend:friend];

    __block BOOL blockCalled = NO;
    [self.container updateFriendWithFriendNumber:friendNumber updateBlock:^(OCTFriend *theFriend) {
        blockCalled = YES;
        XCTAssertEqual(friend, theFriend);
    }];

    XCTAssertTrue(blockCalled);

    XCTAssertThrowsSpecificNamed(
        [self.container updateFriendWithFriendNumber:friendNumber updateBlock:nil],
        NSException,
        NSInternalInconsistencyException
    );

    XCTAssertThrowsSpecificNamed(
        [self.container updateFriendWithFriendNumber:friendNumber+1 updateBlock:^(OCTFriend *theFriend) {}],
        NSException,
        NSInternalInconsistencyException
    );
}

- (void)testRemoveFriend
{
    id friend = OCMClassMock([OCTFriend class]);

    [self.container addFriend:friend];
    [self.container removeFriend:friend];

    XCTAssertTrue(self.container.friends.count == 0);

    XCTAssertThrowsSpecificNamed([self.container removeFriend:nil], NSException, NSInternalInconsistencyException);
    // friend not found
    XCTAssertThrowsSpecificNamed([self.container removeFriend:friend], NSException, NSInternalInconsistencyException);
}

@end
