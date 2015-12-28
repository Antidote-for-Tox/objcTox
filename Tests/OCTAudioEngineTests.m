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

@property (strong, nonatomic) id audioSession;
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

    self.audioEngine = [[OCTAudioEngine alloc] init];
}

- (void)tearDown
{
    refToSelf = NULL;

    self.audioSession = nil;
    self.audioEngine = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
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

- (void)testStoppingAudioFlowFailure
{
    NSError *err;
    XCTAssertTrue([self.audioEngine startAudioFlow:&err]);
    XCTAssertFalse([self.audioEngine stopAudioFlow:&err]);
    XCTAssertNotNil(err);
}

- (void)testSettingDevicesLive
{
 #if ! TARGET_OS_IPHONE
    NSError *err;
    XCTAssertTrue([self.audioEngine startAudioFlow:&err]);
    XCTAssertTrue([self.audioEngine setOutputDeviceID:@"Crystinger" error:nil]);
    XCTAssertTrue([self.audioEngine setInputDeviceID:@"Daxx" error:nil]);
 #else
    XCTAssertTrue([self.audioEngine setOutputDeviceID:OCTOutputDeviceSpeaker error:nil]);
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

 #pragma mark mocked audio engine functions
