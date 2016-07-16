//
//  OCTAudioQueueTests.m
//  objcTox
//
//  Created by stal on 5/26/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "OCTCAsserts.h"
#import "OCTAudioEngine+Private.h"
#import "OCTAudioQueue.h"
#import "OCTManagerConstants.h"

#include "CoreAudioMocks.h"

@import AVFoundation;

static void *refToSelf;
static AudioQueueInputCallback callForInput;
static AudioQueueOutputCallback callForOutput;

const OCTToxAVPCMData pcm[8] = {2, 4, 6, 8, 10, 12, 14, 16};

OSStatus PASSING_AudioQueueNewOutput(const AudioStreamBasicDescription *inFormat,
                                     AudioQueueOutputCallback inCallbackProc,
                                     void *inUserData,
                                     CFRunLoopRef inCallbackRunLoop,
                                     CFStringRef inCallbackRunLoopMode,
                                     UInt32 inFlags,
                                     AudioQueueRef *outAQ)
{
    *outAQ = (void *)0x1234567;
    callForOutput = inCallbackProc;
    return 0;
}


OSStatus PASSING_AudioQueueNewInput(const AudioStreamBasicDescription *inFormat,
                                    AudioQueueInputCallback inCallbackProc,
                                    void *inUserData,
                                    CFRunLoopRef inCallbackRunLoop,
                                    CFStringRef inCallbackRunLoopMode,
                                    UInt32 inFlags,
                                    AudioQueueRef *outAQ)
{
    *outAQ = (void *)0x1234567;
    callForInput = inCallbackProc;
    return 0;
}

typedef struct NotAudioQueueBuffer {
    UInt32 mAudioDataBytesCapacity; // 4 (8)
    void *mAudioData; // 8
    UInt32 mAudioDataByteSize; // 4 (8)
    void *__nullable mUserData; // 8

    const UInt32 mPacketDescriptionCapacity; // 4 (8)
    AudioStreamPacketDescription *const __nullable mPacketDescriptions; // (8)
    UInt32 mPacketDescriptionCount; //  4
} NotAudioQueueBuffer;

OSStatus PASSING_AudioQueueAllocateBuffer(AudioQueueRef inAQ, UInt32 inBufferByteSize, AudioQueueBufferRef *outBuffer)
{
    NotAudioQueueBuffer *buf = calloc(sizeof(AudioQueueBuffer) + inBufferByteSize, 1);
    buf->mAudioData = ((uint8_t *)buf) + sizeof(struct AudioQueueBuffer);
    buf->mAudioDataBytesCapacity = inBufferByteSize;
    buf->mAudioDataByteSize = inBufferByteSize;

    *outBuffer = (AudioQueueBufferRef)buf;
    return 0;
}

OSStatus PASSING_AudioQueueFreeBuffer(AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    free(inBuffer);
    return 0;
}

#if ! TARGET_OS_IPHONE
OSStatus PASSING_AudioObjectGetPropertyData(AudioObjectID inObjectID,
                                            const AudioObjectPropertyAddress *inAddress,
                                            UInt32 inQualifierDataSize,
                                            const void *inQualifierData,
                                            UInt32 *ioDataSize,
                                            void *outData)
{
    if (inObjectID == kAudioObjectSystemObject) {
        CCCAssertTrue(outData != NULL);
        CCCAssertTrue(*ioDataSize == sizeof(AudioDeviceID));
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
#endif

OSStatus FAILING_AudioQueueSetProperty(AudioQueueRef inAQ,
                                       AudioQueuePropertyID inID,
                                       const void *inData,
                                       UInt32 inDataSize)
{
    if (inID == kAudioQueueProperty_CurrentDevice) {
        CCCAssertNotEqual(inData, nil);
        CCCAssertEqual(inDataSize, sizeof(CFStringRef *));

        return -1;
    }
    return 0;
}

OSStatus PASSING_AudioQueueStart(AudioQueueRef inAQ,
                                 const AudioTimeStamp *inStartTime)
{
    CCCAssert(inAQ != NULL);
    return 0;
}


DECLARE_GENERIC_PASS(_AudioQueueDispose)
DECLARE_GENERIC_PASS(_AudioQueueEnqueueBuffer)
DECLARE_GENERIC_PASS(_AudioQueueSetProperty)
DECLARE_GENERIC_PASS(_AudioQueueStop)

DECLARE_GENERIC_FAIL(_AudioQueueDispose)
DECLARE_GENERIC_FAIL(_AudioQueueEnqueueBuffer)
DECLARE_GENERIC_FAIL(_AudioQueueNewInput)
DECLARE_GENERIC_FAIL(_AudioQueueNewOutput)
DECLARE_GENERIC_FAIL(_AudioQueueStart)
DECLARE_GENERIC_FAIL(_AudioQueueStop)

@interface OCTAudioQueueTests : XCTestCase

@property (strong, nonatomic) id audioSession;

@end

@implementation OCTAudioQueueTests

- (void)setUp
{
    [super setUp];

    refToSelf = (__bridge void *)(self);

#if TARGET_OS_IPHONE
    OCMStub([self.audioSession sampleRate]).andReturn(44100.00);
    // Put setup code here. This method is called before the invocation of each test method in the class.
#endif

    RESTORE_PATCHES

#if ! TARGET_OS_IPHONE
    _AudioObjectGetPropertyData = PASSING_AudioObjectGetPropertyData;
#endif
}

- (void)tearDown
{
    refToSelf = NULL;

    self.audioSession = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInitOutput
{
    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithOutputDeviceID:@"Crystinger" error:&error];

    XCTAssertNotNil(oq);
    XCTAssertNotEqual([oq getBufferPointer], NULL);
}

- (void)testInitInput
{
    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithInputDeviceID:@"Daxx" error:&error];

    XCTAssertNotNil(oq);
    XCTAssertNotEqual([oq getBufferPointer], NULL);
}

- (void)testInitFail
{
    PATCH_FAILING(_AudioQueueNewOutput);

    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithOutputDeviceID:@"Vint" error:&error];

    XCTAssertNil(oq);
    XCTAssertNotNil(error);


    PATCH_FAILING(_AudioQueueNewInput);

    error = nil;
    oq = [[OCTAudioQueue alloc] initWithInputDeviceID:@"Rita" error:&error];

    XCTAssertNil(oq);
    XCTAssertNotNil(error);
}

- (void)testInitLater
{
    PATCH_FAILING(_AudioQueueSetProperty);

    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithOutputDeviceID:@"Elgarde" error:&error];

    XCTAssertNil(oq);
    XCTAssertNotNil(error);

    error = nil;
    oq = [[OCTAudioQueue alloc] initWithInputDeviceID:@"Kirin" error:&error];

    XCTAssertNil(oq);
    XCTAssertNotNil(error);
}

// setting devices only available on OS X
- (void)testSetDevice
{
#if ! TARGET_OS_IPHONE
    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithInputDeviceID:@"Undine" error:&error];
    XCTAssertNotNil(oq);

    BOOL ok = [oq setDeviceID:@"PXS-04G" error:&error];
    XCTAssertTrue(ok);

    PATCH_FAILING(_AudioQueueSetProperty);
    ok = [oq setDeviceID:@"Nyx" error:&error];
    XCTAssertFalse(ok);
    XCTAssertNotNil(error);
#endif
}

- (void)testSetDefaultDevice
{
    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithInputDeviceID:@"Sayle" error:&error];
    XCTAssertNotNil(oq);

#if ! TARGET_OS_IPHONE
    BOOL ok = [oq setDeviceID:nil error:&error];
    XCTAssertTrue(ok);

    _AudioObjectGetPropertyData = FAILING_AudioObjectGetPropertyData;
    ok = [oq setDeviceID:nil error:&error];
    XCTAssertFalse(ok);
    XCTAssertNotNil(error);

    _AudioObjectGetPropertyData = FAILING_AudioObjectGetPropertyData2;
    error = nil;
    ok = [oq setDeviceID:nil error:&error];
    XCTAssertFalse(ok);
    XCTAssertNotNil(error);
#endif
}

- (void)testStartStop
{
    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithOutputDeviceID:@"Naivy" error:&error];

    XCTAssertNotNil(oq);
    XCTAssertNotEqual([oq getBufferPointer], NULL);

    BOOL ok = [oq begin:&error];
    XCTAssertTrue(ok);

    ok = [oq stop:&error];
    XCTAssertTrue(ok);
}

- (void)testStartFail
{
    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithOutputDeviceID:@"Vervain" error:&error];

    XCTAssertNotNil(oq);

    PATCH_FAILING(_AudioQueueStart);

    BOOL ok = [oq begin:&error];
    XCTAssertFalse(ok);
    XCTAssertNotNil(error);

    ok = [oq stop:&error];
    XCTAssertTrue(ok);
}

- (void)testStopFail
{
    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithOutputDeviceID:@"Raijin" error:&error];

    XCTAssertNotNil(oq);

    PATCH_FAILING(_AudioQueueStop);

    BOOL ok = [oq begin:&error];
    XCTAssertTrue(ok);

    ok = [oq stop:&error];
    XCTAssertFalse(ok);
    XCTAssertNotNil(error);
}

- (void)testChangeSampleRate
{
    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithOutputDeviceID:@"Minari" error:&error];

    XCTAssertNotNil(oq);

    BOOL ok = [oq begin:&error];
    XCTAssertTrue(ok);

    ok = [oq updateSampleRate:96000.0 numberOfChannels:2.0 error:&error];
    XCTAssertTrue(ok);
}

- (void)testChangeSampleRateFail
{
    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithOutputDeviceID:@"Medis" error:&error];

    XCTAssertNotNil(oq);

    BOOL ok = [oq begin:&error];
    XCTAssertTrue(ok);

    PATCH_FAILING(_AudioQueueNewOutput);

    ok = [oq updateSampleRate:96000.0 numberOfChannels:2.0 error:&error];
    XCTAssertFalse(ok);
    XCTAssertNotNil(error);

    PATCH_PASSING(_AudioQueueNewOutput);

    ok = [oq begin:&error];
    XCTAssertTrue(ok);
}

- (void)testFillOutput
{
    // TODO investigate failing test on travis

    // NSError *error = nil;
    // OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithOutputDeviceID:@"Shadogan" error:&error];

    // XCTAssertNotNil(oq);

    // BOOL ok = [oq begin:&error];
    // XCTAssertTrue(ok);

    // AudioQueueBufferRef buf;

    // // Allocate some extra space because the implementation is supposed to fill
    // // it with 0 if there's not enough data in the ring.

    // PASSING_AudioQueueAllocateBuffer(nil, 32, &buf);
    // XCTAssertNotEqual(buf, NULL);

    // TPCircularBufferProduceBytes([oq getBufferPointer], pcm, 16);
    // callForOutput((__bridge void *)(oq), (void *)0x1234567, buf);

    // OCTToxAVPCMData checkPCM[16];
    // memset((void *)checkPCM, 0, 32);
    // memcpy((void *)checkPCM, pcm, 16);

    // XCTAssertTrue(memcmp(buf->mAudioData, checkPCM, 32) == 0);
    // PASSING_AudioQueueFreeBuffer(nil, buf);
}

- (void)testFillInput
{
    NSError *error = nil;
    OCTAudioQueue *oq = [[OCTAudioQueue alloc] initWithInputDeviceID:@"Nelly" error:&error];

    XCTAssertNotNil(oq);

    BOOL ok = [oq begin:&error];
    XCTAssertTrue(ok);

    AudioQueueBufferRef buf;
    PASSING_AudioQueueAllocateBuffer(nil, 4, &buf);
    XCTAssertNotEqual(buf, NULL);

    __block BOOL sbreak = NO;

    oq.sendDataBlock = ^(void *data, OCTToxAVSampleCount samples, OCTToxAVSampleRate srate, OCTToxAVChannels nchan) {
        sbreak = YES;
    };

    int times = 0;
    while (! sbreak && times < 2000) {
        memcpy(buf->mAudioData, pcm, 4);
        callForInput((__bridge void *_Nullable)(oq),
                     (void *)0x1234567,
                     buf,
                     (void *)0x1,
                     0,
                     NULL);
    }

    XCTAssertTrue(times < 2000);
    // we just have to make sure sendDataBlock is called
    XCTAssertTrue(sbreak);
    PASSING_AudioQueueFreeBuffer(nil, buf);
}

@end
