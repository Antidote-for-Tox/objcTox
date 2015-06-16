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
#import "OCTCAsserts.h"

#import "OCTAudioEngine+Private.h"
@import AVFoundation;

void *refToSelf;

OSStatus mocked_AUGraphIsRunning(AUGraph inGraph, Boolean *outIsRunning);
OSStatus mocked_AUGraphNotRunning(AUGraph inGraph, Boolean *outIsRunning);
OSStatus mocked_AudioUnitSetProperty(AudioUnit inUnit,
                                     AudioUnitPropertyID inID,
                                     AudioUnitScope inScope,
                                     AudioUnitElement inElement,
                                     const void *inData,
                                     UInt32 inDataSize
);

OSStatus mocked_success_inGraph(AUGraph inGraph);
OSStatus mocked_fail_inGraph(AUGraph inGraph);

@interface OCTAudioEngineTests : XCTestCase

@property (strong, nonatomic) id audioSession;
@property (strong, nonatomic) id audioEngine;

@end

@implementation OCTAudioEngineTests

- (void)setUp
{
    [super setUp];

    refToSelf = (__bridge void *)(self);

    self.audioSession = OCMClassMock([AVAudioSession class]);
    OCMStub([self.audioSession sharedInstance]).andReturn(self.audioSession);
    OCMStub([self.audioSession sampleRate]).andReturn(44100.00);
    [OCMStub([self.audioSession setPreferredSampleRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    OCMStub([self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:[OCMArg anyObjectRef]]).andReturn(YES);
    [OCMStub([self.audioSession setPreferredIOBufferDuration:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    OCMStub([self.audioSession setActive:YES error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.audioSession setActive:NO error:[OCMArg anyObjectRef]]).andReturn(YES);

    self.audioEngine = [OCTAudioEngine new];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    refToSelf = NULL;

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

- (void)testStartAudioFlow
{
    _AudioUnitSetProperty = mocked_AudioUnitSetProperty;
    _AUGraphStart = mocked_success_inGraph;
    NSError *error;
    XCTAssertTrue([self.audioEngine startAudioFlow:&error]);

    _AUGraphInitialize = mocked_fail_inGraph;
    XCTAssertFalse([self.audioEngine startAudioFlow:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, 1);
}

- (void)testStopAudioFlow
{
    _AudioUnitSetProperty = mocked_AudioUnitSetProperty;
    _AUGraphStop = mocked_success_inGraph;
    _AUGraphStart = mocked_success_inGraph;
    XCTAssertTrue([self.audioEngine stopAudioFlow:nil]);

    NSError *error;
    _AUGraphStop = mocked_fail_inGraph;
    XCTAssertFalse([self.audioEngine stopAudioFlow:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, 1);
}

- (void)testIsAudioRunning
{
    _AUGraphIsRunning = mocked_AUGraphIsRunning;
    XCTAssertTrue([self.audioEngine isAudioRunning:nil]);

    NSError *error;
    _AUGraphIsRunning = mocked_AUGraphNotRunning;
    XCTAssertFalse([self.audioEngine isAudioRunning:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, 1);
}

- (void)testStartingGraph
{
    NSError *error;
    _AudioUnitSetProperty = mocked_AudioUnitSetProperty;
    _AUGraphInitialize = mocked_success_inGraph;
    _AUGraphStart = mocked_fail_inGraph;
    XCTAssertFalse([self.audioEngine startAudioFlow:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, 1);

    _AUGraphStart = mocked_success_inGraph;
    XCTAssertTrue([self.audioEngine startAudioFlow:nil]);
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

#pragma mark mocked audio engine functions


OSStatus mocked_AUGraphIsRunning(AUGraph inGraph, Boolean *outIsRunning)
{
    OCTAudioEngine *engine = [(__bridge OCTAudioEngineTests *)refToSelf audioEngine];
    CCCAssertEqual(engine.processingGraph, inGraph);

    *outIsRunning = true;

    return noErr;
}

OSStatus mocked_AUGraphNotRunning(AUGraph inGraph, Boolean *outIsRunning)
{
    OCTAudioEngine *engine = [(__bridge OCTAudioEngineTests *)refToSelf audioEngine];
    CCCAssertEqual(engine.processingGraph, inGraph);

    return 1;
}
OSStatus mocked_AudioUnitSetProperty(AudioUnit inUnit,
                                     AudioUnitPropertyID inID,
                                     AudioUnitScope inScope,
                                     AudioUnitElement inElement,
                                     const void *inData,
                                     UInt32 inDataSize
)
{
    OCTAudioEngine *engine = [(__bridge OCTAudioEngineTests *)refToSelf audioEngine];
    CCCAssertEqual(engine.ioUnit, inUnit);

    return noErr;
}

OSStatus mocked_fail_inGraph(AUGraph inGraph)
{
    OCTAudioEngine *engine = [(__bridge OCTAudioEngineTests *)refToSelf audioEngine];
    CCCAssertEqual(engine.processingGraph, inGraph);
    return 1;
}

OSStatus mocked_success_inGraph(AUGraph inGraph)
{
    OCTAudioEngine *engine = [(__bridge OCTAudioEngineTests *)refToSelf audioEngine];
    CCCAssertEqual(engine.processingGraph, inGraph);
    return noErr;
}
