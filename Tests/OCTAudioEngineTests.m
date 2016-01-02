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

@property (strong, nonatomic) void (^sendDataBlock)(void *, OCTToxAVSampleCount, OCTToxAVSampleRate, OCTToxAVChannels);

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
    [OCMStub([self.audioSession overrideOutputAudioPort:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
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
    OCMStub([(id)self.audioEngine makeQueues:[OCMArg anyObjectRef]]).andDo(^(NSInvocation *invocation) {
        id ae;
        [invocation getArgument:&ae atIndex:0];

        [ae setOutputQueue:self.outputMock];
        [ae setInputQueue:self.inputMock];
    });
}

- (void)testStartStopAudioFlow
{
    [self enableMockQueues];

    id toxav = OCMClassMock([OCTToxAV class]);
    OCMStub([toxav sendAudioFrame:[OCMArg anyPointer] sampleCount:0 channels:0 sampleRate:0 toFriend:0 error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.audioEngine toxav]).andReturn(toxav);

    OCMStub([self.inputMock begin:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.outputMock begin:[OCMArg anyObjectRef]]).andReturn(YES);

    OCMStub([self.inputMock stop:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.outputMock stop:[OCMArg anyObjectRef]]).andReturn(YES);

    NSError *error = nil;
    XCTAssertTrue([self.audioEngine startAudioFlow:&error]);
    XCTAssertTrue([self.audioEngine stopAudioFlow:&error]);
}

- (void)testStartStopAudioFlowFail
{
    [self enableMockQueues];

    OCMStub([self.inputMock begin:[OCMArg anyObjectRef]]).andDo(^(NSInvocation *invocation) {
        NSError *__autoreleasing *err;
        [invocation getArgument:&err atIndex:2];

        if (err) {
            *err = [NSError new];
        }

        BOOL no = NO;
        [invocation setReturnValue:&no];
    });

    OCMStub([self.outputMock begin:[OCMArg anyObjectRef]]).andDo(^(NSInvocation *invocation) {
        NSError *__autoreleasing *err;
        [invocation getArgument:&err atIndex:2];

        if (err) {
            *err = [NSError new];
        }

        BOOL no = NO;
        [invocation setReturnValue:&no];
    });


    NSError *error = nil;
    XCTAssertFalse([self.audioEngine startAudioFlow:&error]);
    XCTAssertNotNil(error);
}

- (void)testSettingDevice
{
#if ! TARGET_OS_IPHONE
    XCTAssertTrue([self.audioEngine setOutputDeviceID:@"Sayle" error:nil]);
    XCTAssertTrue([self.audioEngine setInputDeviceID:@"Laives" error:nil]);

    // Device ID should stay in sync with set.
    XCTAssertEqualObjects(self.audioEngine.outputDeviceID, @"Sayle");
    XCTAssertEqualObjects(self.audioEngine.inputDeviceID, @"Laives");
#else
    XCTAssertTrue([self.audioEngine setOutputDeviceID:OCTOutputDeviceSpeaker error:nil]);
    OCMVerify([self.audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:[OCMArg anyObjectRef]]);
    XCTAssertThrows([self.audioEngine setInputDeviceID:OCTInputDeviceDefault error:nil]);

    // Device ID should stay in sync with set.
    XCTAssertEqual(self.audioEngine.outputDeviceID, OCTOutputDeviceSpeaker);
#endif
}

// No test for iOS because it doesn't do anything anyway
- (void)testSettingDevicesLive
{
#if ! TARGET_OS_IPHONE
    NSError *err;
    [self enableMockQueues];

    OCMStub([self.inputMock begin:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.outputMock begin:[OCMArg anyObjectRef]]).andReturn(YES);
    XCTAssertTrue([self.audioEngine startAudioFlow:&err]);

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
#endif
}

- (void)testSendDataBlock
{
    [self enableMockQueues];

    id toxav = OCMClassMock([OCTToxAV class]);
    OCMStub([self.audioEngine toxav]).andReturn(toxav);

    OCMStub([self.inputMock setSendDataBlock:[OCMArg any]]).andDo(^(NSInvocation *invoc) {
        void (^sendDataBlock)(void *, OCTToxAVSampleCount, OCTToxAVSampleRate, OCTToxAVChannels);
        [invoc getArgument:&sendDataBlock atIndex:2];
        self.sendDataBlock = sendDataBlock;
    });

    OCMStub([self.inputMock begin:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.outputMock begin:[OCMArg anyObjectRef]]).andReturn(YES);

    NSError *error = nil;
    self.audioEngine.friendNumber = 0;
    XCTAssertTrue([self.audioEngine startAudioFlow:&error]);

    OCTToxAVPCMData pcm[] = {0x52, 0x2d, 0x4f, 0x2d, 0x4d, 0x2d, 0x41, 0x2d, 0x4e, 0x2d, 0x54, 0x2d, 0x49, 0x2d, 0x43, 0x2d, 0x21, 0x21};
    self.sendDataBlock((void *)pcm, 9, 48000, 1);

    OCMVerify([toxav sendAudioFrame:pcm sampleCount:9 channels:1 sampleRate:48000 toFriend:0 error:[OCMArg anyObjectRef]]);
}

- (void)testReceiveAudioPackets
{
    [self enableMockQueues];

    TPCircularBuffer buffer;
    TPCircularBufferInit(&buffer, 256);

    OCMStub([self.inputMock begin:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.outputMock begin:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.outputMock getBufferPointer]).andReturn(&buffer);

    NSError *error = nil;
    self.audioEngine.friendNumber = 0;
    XCTAssertTrue([self.audioEngine startAudioFlow:&error]);

    OCTToxAVPCMData pcm[] = {0x52, 0x2d, 0x4f, 0x2d, 0x4d, 0x2d, 0x41, 0x2d, 0x4e, 0x2d, 0x54, 0x2d, 0x49, 0x2d, 0x43, 0x2d, 0x21, 0x21};
    [self.audioEngine provideAudioFrames:pcm sampleCount:9 channels:1 sampleRate:12 fromFriend:0];

    int32_t nbytes;
    void *samples = TPCircularBufferTail(&buffer, &nbytes);

    XCTAssertTrue(nbytes == 18);
    XCTAssertTrue(memcmp(samples, pcm, 18) == 0);

    TPCircularBufferCleanup(&buffer);

    OCMVerify([self.outputMock updateSampleRate:12 numberOfChannels:1 error:[OCMArg anyObjectRef]]);
}

@end
