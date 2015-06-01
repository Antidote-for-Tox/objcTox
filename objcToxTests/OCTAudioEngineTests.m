//
//  OCTAudioEngineTests.m
//  objcTox
//
//  Created by Chuong Vu on 5/26/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "OCTAudioEngine.h"
@import AVFoundation;

@interface OCTAudioEngine (tests)
- (void)fillError:(NSError **)error
         withCode:(NSUInteger)code
      description:(NSString *)description
    failureReason:(NSString *)failureReason;

@end
@interface OCTAudioEngineTests : XCTestCase

@property (strong, nonatomic) id audioSession;
@property (strong, nonatomic) id audioEngine;

@end

@implementation OCTAudioEngineTests

- (void)setUp
{
    [super setUp];

    self.audioSession = OCMClassMock([AVAudioSession class]);
    OCMStub([self.audioSession sharedInstance]).andReturn(self.audioSession);
    OCMStub([self.audioSession sampleRate]).andReturn(44100.00);
    OCMStub([self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.audioSession setActive:YES error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.audioSession setActive:NO error:[OCMArg anyObjectRef]]).andReturn(YES);

    self.audioEngine = OCMPartialMock([OCTAudioEngine new]);
    OCMStub([self.audioEngine changeScope:OCTInput enable:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(YES);
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    self.audioSession = nil;
    self.audioEngine = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    NSError *error;
    OCTAudioEngine *engine = [OCTAudioEngine new];
    XCTAssertNotNil(engine);
    XCTAssertFalse([engine isAudioRunning:&error]);
}

- (void)testStartAndStopAudioFlow
{
    ////    Uncomment when testing
    //    NSError *error;
    //    XCTAssertTrue([self.audioEngine startAudioFlow:&error]);
    //    OCMExpect([self.audioEngine changeScope:OCTInput enable:YES error:[OCMArg anyObjectRef]]);
    //    XCTAssertTrue([self.audioEngine isAudioRunning:&error]);
    //    XCTAssertNil(error);
    //
    //    XCTAssertTrue([self.audioEngine stopAudioFlow:&error]);
    //    XCTAssertNil(error);
    //    XCTAssertFalse([self.audioEngine isAudioRunning:&error]);
    //    XCTAssertNil(error);
}

- (void)testFillError
{
    NSError *error;
    [self.audioEngine fillError:&error
                       withCode:2
                    description:@"Test"
                  failureReason:@"TestFailure"];
    XCTAssertEqual(error.localizedDescription, @"Test");
    XCTAssertEqual(error.localizedFailureReason, @"TestFailure");
    XCTAssertEqual(error.code, 2);

    // No exception should be thrown here if error is nil.
    [self.audioEngine fillError:nil
                       withCode:4
                    description:@"Test"
                  failureReason:@"TestFailure"];
}
@end
