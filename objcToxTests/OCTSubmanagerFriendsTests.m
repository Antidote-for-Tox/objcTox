//
//  OCTSubmanagerFriendsTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OCTSubmanagerFriends.h"

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
    XCTAssertNotNil(friends.container);
}

@end
