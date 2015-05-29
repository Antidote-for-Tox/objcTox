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
    OCMStub([self.audioEngine microphoneInput:YES error:[OCMArg anyObjectRef]]).andReturn(YES);
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    self.audioSession = nil;
    self.audioEngine = nil;
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
    NSError *error;
    XCTAssertTrue([self.audioEngine startAudioFlow:&error]);
    XCTAssertTrue([self.audioEngine isAudioRunning:&error]);
    XCTAssertNil(error);

    XCTAssertTrue([self.audioEngine stopAudioFlow:&error]);
    XCTAssertNil(error);
    XCTAssertFalse([self.audioEngine isAudioRunning:&error]);
    XCTAssertNil(error);
}

@end
