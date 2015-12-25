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

#include "CoreAudioMocks.h"

// Get arund const-ness.
#define FORCE_ASSIGN_TO_MEMORY(type, expr1, expr2) { type *b = (type *)&(expr1); *b = expr2; }

OSStatus PASSING_AudioQueueAllocateBuffer(AudioQueueRef inAQ, UInt32 inBufferByteSize, AudioQueueBufferRef *outBuffer)
{
    struct AudioQueueBuffer *buf = calloc(sizeof(struct AudioQueueBuffer) + 16, 1);
    FORCE_ASSIGN_TO_MEMORY(void *, buf->mAudioData, buf + sizeof(struct AudioQueueBuffer))
    FORCE_ASSIGN_TO_MEMORY(UInt32, buf->mAudioDataBytesCapacity, 16)
    buf->mAudioDataByteSize = 16;

    *outBuffer = buf;
    return 0;
}

OSStatus PASSING_AudioQueueFreeBuffer(AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    free(inBuffer);
    return 0;
}

OSStatus PASSING_AudioObjectGetPropertyData(AudioObjectID inObjectID,
                                            const AudioObjectPropertyAddress *inAddress,
                                            UInt32 inQualifierDataSize,
                                            const void *inQualifierData,
                                            UInt32 *ioDataSize,
                                            void *outData)
{
    if (inObjectID == kAudioObjectSystemObject) {
        // we can't do this in C functions :(
        // XCTAssertTrue(outData != NULL);
        // XCTAssertTrue(*ioDataSize == sizeof(AudioDeviceID));
        *(AudioDeviceID *)outData = 0x1234567;
        return 0;
    }

    if (inAddress->mSelector == kAudioDevicePropertyDeviceUID) {
        CFStringRef ret = CFSTR("PXS-04G");
        *(CFStringRef *)outData = CFStringCreateCopy(nil, ret);
        return 0;
    }

    return -1;
}

OSStatus FAILING_AudioObjectGetPropertyData(AudioObjectID inObjectID,
                                            const AudioObjectPropertyAddress *inAddress,
                                            UInt32 inQualifierDataSize,
                                            const void *inQualifierData,
                                            UInt32 *ioDataSize,
                                            void *outData)
{
    if (inObjectID == kAudioObjectSystemObject) {
        return -1;
    }
    return -1;
}

OSStatus FAILING_AudioObjectGetPropertyData2(AudioObjectID inObjectID,
                                             const AudioObjectPropertyAddress *inAddress,
                                             UInt32 inQualifierDataSize,
                                             const void *inQualifierData,
                                             UInt32 *ioDataSize,
                                             void *outData)
{
    if (inObjectID == kAudioObjectSystemObject) {
        *(AudioDeviceID *)outData = 0x1234567;
        return 0;
    }
    if (inAddress->mSelector == kAudioDevicePropertyDeviceUID) {
        return -1;
    }
    return -1;
}

DECLARE_GENERIC_PASS(_AudioQueueDispose)
DECLARE_GENERIC_PASS(_AudioQueueEnqueueBuffer)
DECLARE_GENERIC_PASS(_AudioQueueNewInput)
DECLARE_GENERIC_PASS(_AudioQueueNewOutput)
DECLARE_GENERIC_PASS(_AudioQueueSetProperty)
DECLARE_GENERIC_PASS(_AudioQueueStart)
DECLARE_GENERIC_PASS(_AudioQueueStop)

DECLARE_GENERIC_FAIL(_AudioQueueDispose)
DECLARE_GENERIC_FAIL(_AudioQueueEnqueueBuffer)
DECLARE_GENERIC_FAIL(_AudioQueueNewInput)
DECLARE_GENERIC_FAIL(_AudioQueueNewOutput)
DECLARE_GENERIC_FAIL(_AudioQueueSetProperty)
DECLARE_GENERIC_FAIL(_AudioQueueStart)
DECLARE_GENERIC_FAIL(_AudioQueueStop)

@import AVFoundation;

static void *refToSelf;

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
    // Put setup code here. This method is called before the invocation of each test method in the class.
#endif

    self.audioEngine = [[OCTAudioEngine alloc] init];

    RESTORE_PATCHES
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
    PATCH_FAILING(_AudioQueueSetProperty);
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
    PATCH_FAILING(_AudioQueueStop);

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

- (void)testSettingNilDevicesLiveFailMacOS
{
#if ! TARGET_OS_IPHONE
    _AudioObjectGetPropertyData = FAILING_AudioObjectGetPropertyData;

    XCTAssertTrue([self.audioEngine startAudioFlow:nil]);
    XCTAssertFalse([self.audioEngine setOutputDeviceID:nil error:nil]);

    _AudioObjectGetPropertyData = FAILING_AudioObjectGetPropertyData2;

    XCTAssertTrue([self.audioEngine startAudioFlow:nil]);
    XCTAssertFalse([self.audioEngine setOutputDeviceID:nil error:nil]);
#endif
}

@end

#pragma mark mocked audio engine functions
