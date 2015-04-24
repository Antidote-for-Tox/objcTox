//
//  OCTDBMessageTextTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OCTDBMessageText.h"
#import "OCTMessageText+Private.h"
#import "OCTMessageAbstract+Private.h"
#import "OCTFriend+Private.h"

@interface OCTDBMessageTextTests : XCTestCase

@end

@implementation OCTDBMessageTextTests

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
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 5;

    OCTMessageText *message = [OCTMessageText new];
    message.date = [NSDate date];
    message.isOutgoing = YES;
    message.sender = friend;
    message.text = @"text";
    message.isDelivered = YES;

    OCTDBMessageText *db = [[OCTDBMessageText alloc] initWithMessageText:message];

    XCTAssertNotNil(db);
    XCTAssertEqual(db.dateInterval, [message.date timeIntervalSince1970]);
    XCTAssertEqual(db.isOutgoing, message.isOutgoing);
    XCTAssertEqual(db.senderFriendNumber, message.sender.friendNumber);
    XCTAssertEqualObjects(db.text, message.text);
    XCTAssertEqual(db.isDelivered, message.isDelivered);
}

- (void)testMessage
{
    OCTDBMessageText *db = [OCTDBMessageText new];
    db.dateInterval = [[NSDate date] timeIntervalSince1970];
    db.isOutgoing = YES;
    db.senderFriendNumber = 5;
    db.text = @"text";
    db.isDelivered = YES;

    OCTMessageText *message = [db message];

    XCTAssertNotNil(message);
    XCTAssertEqual(db.dateInterval, [message.date timeIntervalSince1970]);
    XCTAssertEqual(db.isOutgoing, message.isOutgoing);
    XCTAssertEqual(db.senderFriendNumber, message.sender.friendNumber);
    XCTAssertEqualObjects(db.text, message.text);
    XCTAssertEqual(db.isDelivered, message.isDelivered);
}

@end
