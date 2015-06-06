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
#import "OCTBasicContainer.h"
#import "OCTFriend.h"

static NSString *const kSortStorageKey = @"OCTFriendsContainer.sortStorageKey";

@interface OCTFriendsContainer (Tests)

@property (strong, nonatomic) NSMutableArray *friends;
- (NSComparator)comparatorForCurrentSort;

@end

@interface OCTFriend (Tests)
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

- (void)testInit
{
    NSArray *friends = @[ OCMClassMock([OCTFriend class]) ];

    id bs = OCMClassMock([OCTBasicContainer class]);
    OCMStub([bs alloc]).andReturn(bs);
    OCMExpect([(OCTBasicContainer *)bs initWithObjects:friends]);

    OCTFriendsContainer *container = [[OCTFriendsContainer alloc] initWithFriendsArray:friends];

    XCTAssertNotNil(container);
    OCMVerifyAll(bs);
    [bs stopMocking];
}

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
    id bs = OCMClassMock([OCTBasicContainer class]);
    OCMStub([bs alloc]).andReturn(bs);
    OCMStub([(OCTBasicContainer *)bs initWithObjects:[OCMArg any]]).andReturn(bs);
    OCMStub([bs count]).andReturn(5);

    OCTFriendsContainer *container = [[OCTFriendsContainer alloc] initWithFriendsArray:nil];

    XCTAssertEqual([container friendsCount], 5);

    [bs stopMocking];
}

- (void)testFriendAtIndex
{
    id bs = OCMClassMock([OCTBasicContainer class]);
    OCMStub([bs alloc]).andReturn(bs);
    OCMStub([(OCTBasicContainer *)bs initWithObjects:[OCMArg any]]).andReturn(bs);
    OCMStub([bs objectAtIndex:3]).andReturn(@4);

    OCTFriendsContainer *container = [[OCTFriendsContainer alloc] initWithFriendsArray:nil];

    XCTAssertEqual([container friendAtIndex:3], (id)@4);

    [bs stopMocking];
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
    id friend = @1;

    id bs = OCMClassMock([OCTBasicContainer class]);
    OCMStub([bs alloc]).andReturn(bs);
    OCMStub([(OCTBasicContainer *)bs initWithObjects:[OCMArg any]]).andReturn(bs);
    OCMExpect([bs addObject:friend]);

    OCTFriendsContainer *container = [[OCTFriendsContainer alloc] initWithFriendsArray:nil];

    [container addFriend:friend];

    OCMVerifyAll(bs);
    [bs stopMocking];
}

- (void)testUpdateFriend
{
    id updateBlock = @1;

    id checkTestBlock = ^BOOL (BOOL (^block)(OCTFriend *f, NSUInteger idx, BOOL *stop)) {
        id friendMock = OCMClassMock([OCTFriend class]);
        OCMStub([friendMock friendNumber]).andReturn(2);

        return block(friendMock, 0, nil);
    };

    id bs = OCMClassMock([OCTBasicContainer class]);
    OCMStub([bs alloc]).andReturn(bs);
    OCMStub([(OCTBasicContainer *)bs initWithObjects:[OCMArg any]]).andReturn(bs);
    OCMExpect([bs updateObjectPassingTest:[OCMArg checkWithBlock:checkTestBlock] updateBlock:updateBlock]);

    OCTFriendsContainer *container = [[OCTFriendsContainer alloc] initWithFriendsArray:nil];

    [container updateFriendWithFriendNumber:2 updateBlock:updateBlock];

    OCMVerifyAll(bs);
    [bs stopMocking];
}

- (void)testRemoveFriend
{
    id friend = @1;

    id bs = OCMClassMock([OCTBasicContainer class]);
    OCMStub([bs alloc]).andReturn(bs);
    OCMStub([(OCTBasicContainer *)bs initWithObjects:[OCMArg any]]).andReturn(bs);
    OCMExpect([bs removeObject:friend]);

    OCTFriendsContainer *container = [[OCTFriendsContainer alloc] initWithFriendsArray:nil];

    [container removeFriend:friend];

    OCMVerifyAll(bs);
    [bs stopMocking];
}

@end
