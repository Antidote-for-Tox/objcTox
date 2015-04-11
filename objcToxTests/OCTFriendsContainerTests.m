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

#import "OCTFriendsContainer.h"

static NSString *const kSortStorageKey = @"OCTFriendsContainer.sortStorageKey";

@interface OCTFriendsContainer(Tests)

@property (strong, nonatomic) NSMutableArray *friends;

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
    self.container.friendsSort = OCTManagerFriendsSortByName;
}

- (void)tearDown
{
    self.container = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark -  Test public methods

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
    OCMStub([storage objectForKey:[OCMArg isEqual:kSortStorageKey]]).andReturn(@(OCTManagerFriendsSortByName));

    id dataSource = OCMProtocolMock(@protocol(OCTFriendsContainerDataSource));
    OCMStub([dataSource friendsContainerGetSettingsStorage]).andReturn(storage);

    self.container.dataSource = dataSource;
    [self.container configure];

    XCTAssertEqual(self.container.friendsSort, OCTManagerFriendsSortByName);
}

- (void)testConfigure2
{
    id storage = OCMProtocolMock(@protocol(OCTSettingsStorageProtocol));
    OCMStub([storage objectForKey:[OCMArg isEqual:kSortStorageKey]]).andReturn(@(OCTManagerFriendsSortByStatus));

    id dataSource = OCMProtocolMock(@protocol(OCTFriendsContainerDataSource));
    OCMStub([dataSource friendsContainerGetSettingsStorage]).andReturn(storage);

    self.container.dataSource = dataSource;
    [self.container configure];

    XCTAssertEqual(self.container.friendsSort, OCTManagerFriendsSortByStatus);
}

- (void)testAddFriend
{
    id friend = OCMClassMock([OCTFriend class]);

    [self.container addFriend:friend];

    XCTAssertTrue(self.container.friends.count == 1);

    id theFriend = [self.container.friends lastObject];
    XCTAssertEqual(friend, theFriend);
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
}

- (void)testRemoveFriend
{
    id friend = OCMClassMock([OCTFriend class]);

    [self.container addFriend:friend];
    [self.container removeFriend:friend];

    XCTAssertTrue(self.container.friends.count == 0);
}

@end
