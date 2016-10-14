// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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

- (void)testLastActivityDate
{
    OCTChat *chat = [OCTChat new];

    chat.lastActivityDateInterval = 0;
    XCTAssertNil([chat lastActivityDate]);

    chat.lastActivityDateInterval = 12345;
    XCTAssertEqual([[chat lastActivityDate] timeIntervalSince1970], 12345);

    chat.lastActivityDateInterval = -12345;
    XCTAssertNil([chat lastActivityDate]);
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

@end
