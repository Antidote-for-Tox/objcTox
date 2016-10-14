// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <XCTest/XCTest.h>

#import "OCTObject.h"

@interface OCTObjectTests : XCTestCase

@end

@implementation OCTObjectTests

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

- (void)testIsEqual
{
    OCTObject *object = [OCTObject new];
    OCTObject *same = [OCTObject new];
    same.uniqueIdentifier = object.uniqueIdentifier;

    OCTObject *another = [OCTObject new];

    XCTAssertTrue([object isEqual:object]);
    XCTAssertTrue([object isEqual:same]);
    XCTAssertFalse([object isEqual:another]);
}

@end
