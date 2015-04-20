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

@interface OCTSubmanagerFriends(Tests)
- (OCTFriend *)createFriendWithFriendNumber:(OCTToxFriendNumber)friendNumber;
@end

@interface OCTSubmanagerFriendsTests : XCTestCase

@property (strong, nonatomic) OCTSubmanagerFriends *friends;

@end

@implementation OCTSubmanagerFriendsTests

- (void)setUp
{
    [super setUp];
    self.friends = [OCTSubmanagerFriends new];
}

- (void)tearDown
{
    self.friends = nil;
    [super tearDown];
}

- (void)testInit
{
    OCTSubmanagerFriends *friends = [OCTSubmanagerFriends new];

    XCTAssertNotNil(friends);
}

- (void)testConfigure
{
    NSArray *numbersArray = @[@0, @1, @3, @5];
    NSArray *friendsArray = @[
        OCMClassMock([OCTFriend class]),
        OCMClassMock([OCTFriend class]),
        OCMClassMock([OCTFriend class]),
        OCMClassMock([OCTFriend class])];

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox friendsArray]).andReturn(numbersArray);

    id dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));
    OCMStub([dataSource managerGetTox]).andReturn(tox);

    OCTSubmanagerFriends *submanager = [OCTSubmanagerFriends new];

    id friendsContainer = OCMClassMock([OCTFriendsContainer class]);
    OCMStub([friendsContainer alloc]).andReturn(friendsContainer);
    OCMExpect([friendsContainer setDataSource:(id)submanager]);
    OCMExpect([friendsContainer configure]);
    OCMExpect([friendsContainer initWithFriendsArray:[OCMArg checkWithBlock:^BOOL (NSArray *array) {
        XCTAssertEqual(array.count, 4);
        XCTAssertEqual(array[0], friendsArray[0]);
        XCTAssertEqual(array[1], friendsArray[1]);
        XCTAssertEqual(array[2], friendsArray[2]);
        XCTAssertEqual(array[3], friendsArray[3]);

        return YES;
    }]]).andReturn(friendsContainer);

    submanager.dataSource = dataSource;
    submanager = OCMPartialMock(submanager);
    OCMStub([submanager createFriendWithFriendNumber:0]).andReturn(friendsArray[0]);
    OCMStub([submanager createFriendWithFriendNumber:1]).andReturn(friendsArray[1]);
    OCMStub([submanager createFriendWithFriendNumber:3]).andReturn(friendsArray[2]);
    OCMStub([submanager createFriendWithFriendNumber:5]).andReturn(friendsArray[3]);

    [submanager configure];

    XCTAssertEqual(friendsContainer, submanager.friendsContainer);
    OCMVerifyAll(friendsContainer);
}

@end
