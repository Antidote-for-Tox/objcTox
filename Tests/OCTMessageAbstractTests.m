// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <XCTest/XCTest.h>

#import "OCTMessageAbstract.h"
#import "OCTFriend.h"

@interface OCTMessageAbstractTests : XCTestCase

@end

@implementation OCTMessageAbstractTests

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

- (void)testDate
{
    OCTMessageAbstract *message = [OCTMessageAbstract new];

    message.dateInterval = 0;
    XCTAssertNil([message date]);

    message.dateInterval = 12345;
    XCTAssertEqual([[message date] timeIntervalSince1970], 12345);

    message.dateInterval = -12345;
    XCTAssertNil([message date]);
}

- (void)testIsOutgoing
{
    OCTMessageAbstract *message = [OCTMessageAbstract new];

    XCTAssertTrue([message isOutgoing]);

    message.senderUniqueIdentifier = @"Some unique id";
    XCTAssertFalse([message isOutgoing]);
}

@end
