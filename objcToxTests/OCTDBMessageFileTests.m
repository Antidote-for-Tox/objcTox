//
//  OCTDBMessageFileTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OCTDBMessageFile.h"
#import "OCTMessageFile+Private.h"
#import "OCTMessageAbstract+Private.h"
#import "OCTFriend+Private.h"

@interface OCTDBMessageFileTests : XCTestCase

@end

@implementation OCTDBMessageFileTests

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

    OCTMessageFile *message = [OCTMessageFile new];
    message.date = [NSDate date];
    message.isOutgoing = YES;
    message.sender = friend;
    message.fileType = OCTMessageFileTypeLoading;
    message.fileSize = 123;
    message.fileName = @"fileName";
    message.filePath = @"filePath";
    message.fileUTI = @"fileUTI";

    OCTDBMessageFile *db = [[OCTDBMessageFile alloc] initWithMessageFile:message];

    XCTAssertNotNil(db);
    XCTAssertEqual(db.dateInterval, [message.date timeIntervalSince1970]);
    XCTAssertEqual(db.isOutgoing, message.isOutgoing);
    XCTAssertEqual(db.senderFriendNumber, message.sender.friendNumber);
    XCTAssertEqual(db.fileType, message.fileType);
    XCTAssertEqual(db.fileSize, message.fileSize);
    XCTAssertEqualObjects(db.fileName, message.fileName);
    XCTAssertEqualObjects(db.filePath, message.filePath);
    XCTAssertEqualObjects(db.fileUTI, message.fileUTI);
}

- (void)testMessage
{
    OCTDBMessageFile *db = [OCTDBMessageFile new];
    db.dateInterval = [[NSDate date] timeIntervalSince1970];
    db.isOutgoing = YES;
    db.senderFriendNumber = 5;
    db.fileType = 2;
    db.fileSize = 123;
    db.fileName = @"fileName";
    db.filePath = @"filePath";
    db.fileUTI = @"fileUTI";

    OCTMessageFile *message = [db message];

    XCTAssertNotNil(message);
    XCTAssertEqual(db.dateInterval, [message.date timeIntervalSince1970]);
    XCTAssertEqual(db.isOutgoing, message.isOutgoing);
    XCTAssertEqual(db.senderFriendNumber, message.sender.friendNumber);
    XCTAssertEqual(db.fileType, message.fileType);
    XCTAssertEqual(db.fileSize, message.fileSize);
    XCTAssertEqualObjects(db.fileName, message.fileName);
    XCTAssertEqualObjects(db.filePath, message.filePath);
    XCTAssertEqualObjects(db.fileUTI, message.fileUTI);
}

@end
