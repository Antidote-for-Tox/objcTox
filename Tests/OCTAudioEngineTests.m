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

@import AVFoundation;

static void *refToSelf;

OSStatus mocked_AUGraphIsRunning(AUGraph inGraph, Boolean *outIsRunning);
OSStatus mocked_AUGraphNotRunning(AUGraph inGraph, Boolean *outIsRunning);
OSStatus mocked_AudioUnitSetProperty(AudioUnit inUnit,
                                     AudioUnitPropertyID inID,
                                     AudioUnitScope inScope,
                                     AudioUnitElement inElement,
                                     const void *inData,
                                     UInt32 inDataSize
);

OSStatus mocked_AudioUnitRender(AudioUnit inUnit,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                UInt32 inOutputBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList *ioData);

OSStatus mocked_success_inGraph(AUGraph inGraph);
OSStatus mocked_fail_inGraph(AUGraph inGraph);

const OCTToxAVPCMData pcm[8] = {2, 4, 6, 8, 10, 12, 14, 16};
int16_t *pcmRender;

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

    self.audioEngine = [[OCTAudioEngine alloc] init];
    // Put setup code here. This method is called before the invocation of each test method in the class.
#else
#warning TODO audio OSX
#endif
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
#if TARGET_OS_IPHONE
    _AudioUnitSetProperty = mocked_AudioUnitSetProperty;
    _AUGraphStart = mocked_success_inGraph;
    NSError *error;
    XCTAssertTrue([self.audioEngine startAudioFlow:&error]);
#else
#warning TODO audio OSX
#endif
}

- (void)testStopAudioFlow
{
#if TARGET_OS_IPHONE
    _AudioUnitSetProperty = mocked_AudioUnitSetProperty;
    _AUGraphStop = mocked_success_inGraph;
    _AUGraphStart = mocked_success_inGraph;
    XCTAssertTrue([self.audioEngine stopAudioFlow:nil]);

    NSError *error;
    _AUGraphStop = mocked_fail_inGraph;
    XCTAssertFalse([self.audioEngine stopAudioFlow:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, 1);
#else
#warning TODO audio OSX
#endif
}

- (void)testRouteAudioToSpeaker
{
#if TARGET_OS_IPHONE
    [self.audioEngine routeAudioToSpeaker:YES error:nil];
    OCMVerify([self.audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:[OCMArg anyObjectRef]]);

    [self.audioEngine routeAudioToSpeaker:NO error:nil];
    OCMVerify([self.audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:[OCMArg anyObjectRef]]);
#else
#warning TODO audio OSX
#endif
}

- (void)testIsAudioRunning
{
#if TARGET_OS_IPHONE
    _AUGraphIsRunning = mocked_AUGraphIsRunning;
    XCTAssertTrue([self.audioEngine isAudioRunning:nil]);

    NSError *error;
    _AUGraphIsRunning = mocked_AUGraphNotRunning;
    XCTAssertFalse([self.audioEngine isAudioRunning:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, 1);
#else
#warning TODO audio OSX
#endif
}

- (void)testProvideAudioFrames
{
#if TARGET_OS_IPHONE
    OCTToxAVSampleCount sampleCount = 4;
    OCTToxAVChannels channelCount = 2;
    OCTToxAVSampleRate sampleRate = 33333;

    self.audioEngine.friendNumber = 123;
    [self.audioEngine provideAudioFrames:pcm
                             sampleCount:sampleCount
                                channels:channelCount
                              sampleRate:sampleRate
                              fromFriend:123];

    _AudioUnitSetProperty = mocked_AudioUnitSetProperty;
    XCTAssertEqual((int)self.audioEngine.outputBuffer.fillCount, 16);
    XCTAssertEqual(self.audioEngine.outputSampleRate, 33333);
#else
#warning TODO audio OSX
#endif
}

- (void)testStartingGraph
{
#if TARGET_OS_IPHONE
    NSError *error;
    _AudioUnitSetProperty = mocked_AudioUnitSetProperty;
    _AUGraphInitialize = mocked_success_inGraph;
    _AUGraphStart = mocked_fail_inGraph;
    XCTAssertFalse([self.audioEngine startAudioFlow:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, 1);

    _AUGraphStart = mocked_success_inGraph;
    XCTAssertTrue([self.audioEngine startAudioFlow:nil]);
#else
#warning TODO audio OSX
#endif
}

- (void)testInputRenderCallback
{
#if TARGET_OS_IPHONE
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.audioEngine.toxav = toxAV;
    self.audioEngine.friendNumber = 1234;
    self.audioEngine.inputSampleRate = 48000;
    _AudioUnitRender = mocked_AudioUnitRender;

    pcmRender = malloc(1920 * sizeof(SInt16));

    inputRenderCallBack((__bridge void *)(self.audioEngine), 0, 0, 1, 1920, NULL);

    OCMVerify([toxAV sendAudioFrame:[OCMArg anyPointer] sampleCount:1920 channels:2 sampleRate:48000 toFriend:1234 error:[OCMArg anyObjectRef]]);

    free(pcmRender);
#else
#warning TODO audio OSX
#endif
}

- (void)testFillError
{
#if TARGET_OS_IPHONE
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
#else
#warning TODO audio OSX
#endif
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

OSStatus mocked_AudioUnitRender(AudioUnit inUnit,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                UInt32 inOutputBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList *ioData)
{
    ioData->mBuffers[0].mData = pcmRender;

    return noErr;
}
