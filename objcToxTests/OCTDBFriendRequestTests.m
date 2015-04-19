//
//  OCTDBFriendRequestTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OCTDBFriendRequest.h"

@interface OCTDBFriendRequestTests : XCTestCase

@end

@implementation OCTDBFriendRequestTests

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

- (void)testCreateFromFriendRequest
{
    OCTFriendRequest *request = [OCTFriendRequest new];
    request.publicKey = @"key";
    request.message = @"message";

    OCTDBFriendRequest *db = [OCTDBFriendRequest createFromFriendRequest:request];

    XCTAssertNotNil(db);
    XCTAssertEqual(db.publicKey, request.publicKey);
    XCTAssertEqual(db.message, request.message);
}

- (void)testFriendRequest
{
    OCTDBFriendRequest *db = [OCTDBFriendRequest new];
    db.publicKey = @"key";
    db.message = @"message";

    OCTFriendRequest *request = [db friendRequest];

    XCTAssertNotNil(request);
    XCTAssertEqual(db.publicKey, request.publicKey);
    XCTAssertEqual(db.message, request.message);
}

@end
