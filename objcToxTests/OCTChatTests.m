//
//  OCTChatTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24/06/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCTChat.h"
#import "OCTMessageAbstract.h"

@interface OCTChatTests : XCTestCase

@end

@implementation OCTChatTests

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

- (void)testLastReadDate
{
    OCTChat *chat = [OCTChat new];

    chat.lastReadDateInterval = 0;
    XCTAssertNil([chat lastReadDate]);

    chat.lastReadDateInterval = 12345;
    XCTAssertEqual([[chat lastReadDate] timeIntervalSince1970], 12345);

    chat.lastReadDateInterval = -12345;
    XCTAssertNil([chat lastReadDate]);
}

- (void)testCreationDate
{
    OCTChat *chat = [OCTChat new];

    chat.creationDateInterval = 0;
    XCTAssertNil([chat creationDate]);

    chat.creationDateInterval = 12345;
    XCTAssertEqual([[chat creationDate] timeIntervalSince1970], 12345);

    chat.creationDateInterval = -12345;
    XCTAssertNil([chat creationDate]);
}

- (void)testHasUnreadMessages
{
    OCTChat *chat = [OCTChat new];
    chat.lastMessage = [OCTMessageAbstract new];

    XCTAssertFalse([chat hasUnreadMessages]);

    chat.lastReadDateInterval = 10;
    XCTAssertFalse([chat hasUnreadMessages]);

    chat.lastMessage.dateInterval = 20;
    XCTAssertTrue([chat hasUnreadMessages]);

    chat.lastReadDateInterval = 20;
    XCTAssertFalse([chat hasUnreadMessages]);

    chat.lastReadDateInterval = 30;
    XCTAssertFalse([chat hasUnreadMessages]);
}

- (void)testLastActivityDate
{
    OCTChat *chat = [OCTChat new];
    chat.creationDateInterval = 10;

    NSDate *date = [chat lastActivityDate];

    XCTAssertEqual([date timeIntervalSince1970], 10);

    chat.lastMessage = [OCTMessageAbstract new];
    chat.lastMessage.dateInterval = 20;

    date = [chat lastActivityDate];

    XCTAssertEqual([date timeIntervalSince1970], 20);
}

@end
