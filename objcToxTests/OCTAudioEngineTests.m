//
//  OCTAudioEngineTests.m
//  objcTox
//
//  Created by Chuong Vu on 5/26/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "OCTAudioEngine.h"

@interface OCTAudioEngineTests : XCTestCase

@end

@implementation OCTAudioEngineTests

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

- (void)testInit {
    NSError * error;
    OCTAudioEngine *engine = [OCTAudioEngine new];
    XCTAssertNotNil(engine);
    XCTAssertFalse([engine isAudioRunning:&error]);
}

- (void)testStartAndStopAudioFlow
{
    OCTAudioEngine *engine = [OCTAudioEngine new];
    NSError *error;
    XCTAssertTrue([engine startAudioFlow:&error]);
    XCTAssertTrue([engine isAudioRunning:&error]);
    XCTAssertNil(error);

    XCTAssertTrue([engine stopAudioFlow:&error]);
    XCTAssertNil(error);
    XCTAssertFalse([engine isAudioRunning:&error]);
    XCTAssertNil(error);
}

@end
