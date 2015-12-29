//
//  OCTAudioEngineTests.m
//  objcTox
//
//  Created by Chuong Vu on 5/26/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "OCTCAsserts.h"
#import "OCTAudioEngine+Private.h"
#import "OCTAudioQueue.h"
#import "OCTManagerConstants.h"

@import AVFoundation;

static void *refToSelf;

@interface OCTAudioEngineTests : XCTestCase

@property (strong, nonatomic) OCTAudioQueue *outputMock;
@property (strong, nonatomic) OCTAudioQueue *inputMock;
@property (strong, nonatomic) id audioSession;
@property (strong, nonatomic) OCTAudioEngine *realAudioEngine;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;

@end

@implementation OCTAudioEngineTests

- (void)setUp
{
    [super setUp];

    refToSelf = (__bridge void *)(self);

#if TARGET_OS_IPHONE
    self.audioSession = OCMClassMock([AVAudioSession class]);
    OCMStub([self.audioSession sharedInstance]).andReturn(self.audioSession);
    OCMStub([self.audioSession sampleRate]).andReturn(44100.00);
    [OCMStub([self.audioSession setPreferredSampleRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    OCMStub([self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:[OCMArg anyObjectRef]]).andReturn(YES);
    [OCMStub([self.audioSession setPreferredIOBufferDuration:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    OCMStub(([self.audioSession setMode:AVAudioSessionModeVoiceChat error:[OCMArg anyObjectRef]])).andReturn(YES);
    OCMStub([self.audioSession setActive:YES error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.audioSession setActive:NO error:[OCMArg anyObjectRef]]).andReturn(YES);
    // Put setup code here. This method is called before the invocation of each test method in the class.
#endif

    self.realAudioEngine = [[OCTAudioEngine alloc] init];
    self.audioEngine = OCMPartialMock(self.realAudioEngine);

    self.inputMock = OCMClassMock([OCTAudioQueue class]);
    self.outputMock = OCMClassMock([OCTAudioQueue class]);
}

- (void)tearDown
{
    refToSelf = NULL;

    self.audioSession = nil;
    self.audioEngine = nil;
    self.outputMock = nil;
    self.inputMock = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)enableMockQueues
{
    self.outputMock = OCMPartialMock(self.audioEngine.outputQueue);
    [self.audioEngine setOutputQueue:self.outputMock];

    self.inputMock = OCMPartialMock(self.audioEngine.inputQueue);
    [self.audioEngine setInputQueue:self.inputMock];
}

- (void)testStartStopAudioFlow
{
    id toxav = OCMClassMock([OCTToxAV class]);
    OCMStub([toxav sendAudioFrame:[OCMArg anyPointer] sampleCount:0 channels:0 sampleRate:0 toFriend:0 error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.audioEngine toxav]).andReturn(toxav);

    XCTAssertTrue([self.audioEngine startAudioFlow:nil]);
    XCTAssertTrue([self.audioEngine isAudioRunning:nil]);

    OCMVerifyAllWithDelay(toxav, 0.3);

    XCTAssertTrue([self.audioEngine stopAudioFlow:nil]);
    XCTAssertFalse([self.audioEngine isAudioRunning:nil]);
}

- (void)testStartingAudioFlowWithBadDeviceID
{
    XCTAssertTrue([self.audioEngine setOutputDeviceID:@"jkfhsdhfgk" error:nil]);

    NSError *err;
    XCTAssertFalse([self.audioEngine startAudioFlow:&err]);
    XCTAssertNotNil(err);
}

- (void)testStartingAudioFlowWithNilDeviceID
{
    [self.audioEngine setOutputDeviceID:nil error:nil];

    NSError *err;
    XCTAssertTrue([self.audioEngine startAudioFlow:&err]);
    XCTAssertNotEqual([self.audioEngine.outputQueue getBufferPointer], NULL);
}

- (void)testSettingDevicesLive
{
#if ! TARGET_OS_IPHONE
    NSError *err;
    XCTAssertTrue([self.audioEngine startAudioFlow:&err]);

    [self enableMockQueues];
    OCMStub([self.outputMock setDeviceID:@"Crystinger" error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.inputMock setDeviceID:@"Daxx" error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.outputMock setDeviceID:@"Niles" error:[OCMArg anyObjectRef]]).andReturn(NO);

    XCTAssertTrue([self.audioEngine setOutputDeviceID:@"Crystinger" error:nil]);
    XCTAssertTrue([self.audioEngine setInputDeviceID:@"Daxx" error:nil]);

    // Device ID should stay in sync with set.
    XCTAssertEqualObjects(self.audioEngine.outputDeviceID, @"Crystinger");
    XCTAssertEqualObjects(self.audioEngine.inputDeviceID, @"Daxx");

    // Failed sets should not update the stored id.
    XCTAssertFalse([self.audioEngine setOutputDeviceID:@"Niles" error:nil]);
    XCTAssertNotEqualObjects(self.audioEngine.outputDeviceID, @"Niles");
#else
    XCTAssertTrue([self.audioEngine setOutputDeviceID:OCTOutputDeviceSpeaker error:nil]);
    XCTAssertEqualObjects(self.audioEngine.outputDeviceID, OCTOutputDeviceSpeaker);
#endif
}

- (void)testSettingNilDevicesLiveMacOS
{
#if ! TARGET_OS_IPHONE
    NSError *err;
    XCTAssertTrue([self.audioEngine startAudioFlow:&err]);
    XCTAssertTrue([self.audioEngine setOutputDeviceID:nil error:nil]);
#endif
}

@end
