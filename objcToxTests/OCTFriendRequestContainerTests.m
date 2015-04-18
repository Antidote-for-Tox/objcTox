//
//  OCTFriendRequestContainerTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 18.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTFriendRequestContainer.h"
#import "OCTFriendRequestContainer+Private.h"
#import "OCTBasicContainer.h"
#import "OCTManagerConstants.h"

@interface OCTFriendRequestContainerTests : XCTestCase

@end

@implementation OCTFriendRequestContainerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    NSArray *requests = @[ OCMClassMock([OCTFriendRequest class]) ];

    id bs = OCMClassMock([OCTBasicContainer class]);
    OCMStub([bs alloc]).andReturn(bs);

    OCTFriendRequestContainer *container = [[OCTFriendRequestContainer alloc] initWithFriendRequestsArray:requests];

    XCTAssertNotNil(container);
    OCMVerify([bs initWithObjects:requests updateNotificationName:kOCTFriendRequestContainerUpdateNotification]);
    [bs stopMocking];
}

- (void)testAddRequest
{
    id request = @1;

    id bs = OCMClassMock([OCTBasicContainer class]);
    OCMStub([bs alloc]).andReturn(bs);
    OCMStub([bs initWithObjects:[OCMArg any] updateNotificationName:[OCMArg any]]).andReturn(bs);

    OCTFriendRequestContainer *container = [[OCTFriendRequestContainer alloc] initWithFriendRequestsArray:nil];
    [container addRequest:request];

    OCMVerify([bs addObject:request]);
    OCMVerifyAll(bs);
    [bs stopMocking];
}

- (void)testRemoveRequest
{
    id request = @1;

    id bs = OCMClassMock([OCTBasicContainer class]);
    OCMStub([bs alloc]).andReturn(bs);
    OCMStub([bs initWithObjects:[OCMArg any] updateNotificationName:[OCMArg any]]).andReturn(bs);

    OCTFriendRequestContainer *container = [[OCTFriendRequestContainer alloc] initWithFriendRequestsArray:nil];
    [container removeRequest:request];

    OCMVerify([bs removeObject:request]);
    [bs stopMocking];
}

- (void)testRequestsCount
{
    id bs = OCMClassMock([OCTBasicContainer class]);
    OCMStub([bs alloc]).andReturn(bs);
    OCMStub([bs initWithObjects:[OCMArg any] updateNotificationName:[OCMArg any]]).andReturn(bs);
    OCMStub([bs count]).andReturn(5);

    OCTFriendRequestContainer *container = [[OCTFriendRequestContainer alloc] initWithFriendRequestsArray:nil];

    XCTAssertEqual([container requestsCount], 5);
    [bs stopMocking];
}

- (void)testRequestAtIndex
{
    id bs = OCMClassMock([OCTBasicContainer class]);
    OCMStub([bs alloc]).andReturn(bs);
    OCMStub([bs initWithObjects:[OCMArg any] updateNotificationName:[OCMArg any]]).andReturn(bs);
    OCMStub([bs objectAtIndex:3]).andReturn(@4);

    OCTFriendRequestContainer *container = [[OCTFriendRequestContainer alloc] initWithFriendRequestsArray:nil];

    XCTAssertEqual([container requestAtIndex:3], (id)@4);
    [bs stopMocking];
}

@end
