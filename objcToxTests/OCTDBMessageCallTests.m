//
//  OCTDBMessageCallTests.m
//  objcTox
//
//  Created by Chuong Vu on 5/14/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCTDBMessageCall.h"
#import "OCTMessageCall+Private.h"

@interface OCTDBMessageCallTests : XCTestCase

@end

@implementation OCTDBMessageCallTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    OCTMessageCall *message = [OCTMessageCall new];

    message.callDuration = 12345.05;

    XCTAssertNotNil(message);

    OCTDBMessageCall *messageDB = [[OCTDBMessageCall alloc] initWithMessageCall:message];

    XCTAssertNotNil(messageDB);
    XCTAssertEqual(messageDB.callDuration, message.callDuration);
}
@end
