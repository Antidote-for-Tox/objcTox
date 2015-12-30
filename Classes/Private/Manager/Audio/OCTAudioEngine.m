//
//  OCTAudioEngine.m
//  objcTox
//
//  Created by Chuong Vu on 5/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//
#import "OCTAudioEngine+Private.h"
#import "OCTToxAV+Private.h"
#import "OCTAudioQueue.h"
#import "DDLog.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

NSString *const OCTInputDeviceDefault = nil;
NSString *const OCTOutputDeviceDefault = nil;
NSString *const OCTOutputDeviceSpeaker = @"OCTOutputDeviceSpeaker";
NSString *const OCTInputDeviceBackCamera = @"OCTInputDeviceBackCamera";
NSString *const OCTInputDeviceFrontCamera = @"OCTInputDeviceFrontCamera";

@import AVFoundation;

@interface OCTAudioEngine ()

// @property (nonatomic, assign) OCTToxAVSampleRate inputSampleRate;
@property (nonatomic, assign) OCTToxAVSampleRate outputSampleRate;
@property (nonatomic, assign) OCTToxAVChannels outputNumberOfChannels;

@end

@implementation OCTAudioEngine

#pragma mark - LifeCycle
- (instancetype)init
{
    self = [super init];
    if (! self) {
        return nil;
    }

    _enableMicrophone = YES;

    return self;
}

#pragma mark - SPI

- (BOOL)setInputDeviceID:(NSString *)inputDeviceID error:(NSError **)error
{
#if TARGET_OS_IPHONE
    [NSException raise:NSGenericException format:@"setInputDeviceID: is not available on iOS."];
    return NO;
#else
    // if audio is not active, we can't really be bothered to check that the
    // device exists; we rely on startAudioFlow: to fail later.
    if (! self.inputQueue) {
        _inputDeviceID = inputDeviceID;
        return YES;
    }

    if ([self.inputQueue setDeviceID:inputDeviceID error:error]) {
        _inputDeviceID = inputDeviceID;
        return YES;
    }
    else {
        return NO;
    }
#endif
}

- (BOOL)setOutputDeviceID:(NSString *)outputDeviceID error:(NSError **)error
{
#if TARGET_OS_IPHONE
    _outputDeviceID = outputDeviceID;
    AVAudioSession *session = [AVAudioSession sharedInstance];

    AVAudioSessionPortOverride override;
    if (outputDeviceID == OCTOutputDeviceSpeaker) {
        override = AVAudioSessionPortOverrideSpeaker;
    }
    else {
        override = AVAudioSessionPortOverrideNone;
    }

    return [session overrideOutputAudioPort:override error:error];
#else
    if (! self.outputQueue) {
        _outputDeviceID = outputDeviceID;
        return YES;
    }

    if ([self.outputQueue setDeviceID:outputDeviceID error:error]) {
        _outputDeviceID = outputDeviceID;
        return YES;
    }
    else {
        return NO;
    }
#endif
}

- (BOOL)startAudioFlow:(NSError **)error
{
#if TARGET_OS_IPHONE
    AVAudioSession *session = [AVAudioSession sharedInstance];

    if (!
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:error] &&
        [session setPreferredSampleRate:kDefaultSampleRate error:error] &&
        [session setMode:AVAudioSessionModeVoiceChat error:error] &&
        [session setActive:YES error:error]) {
        return NO;
    }
#endif

    // Note: OCTAudioQueue handles the case where the device ids are nil - in that case
    // we don't set the device explicitly, and the default is used.
#if TARGET_OS_IPHONE
    self.outputQueue = [[OCTAudioQueue alloc] initWithOutputDeviceID:nil error:error];
    self.inputQueue = [[OCTAudioQueue alloc] initWithInputDeviceID:nil error:error];
#else
    self.outputQueue = [[OCTAudioQueue alloc] initWithOutputDeviceID:self.outputDeviceID error:error];
    self.inputQueue = [[OCTAudioQueue alloc] initWithInputDeviceID:self.inputDeviceID error:error];
#endif

    if (! (self.outputQueue && self.inputQueue)) {
        return NO;
    }

    OCTAudioEngine *__weak welf = self;
    self.inputQueue.sendDataBlock = ^(void *data, OCTToxAVSampleCount samples, OCTToxAVSampleRate rate, OCTToxAVChannels channelCount) {
        OCTAudioEngine *aoi = welf;

        if (aoi.enableMicrophone) {
            [aoi.toxav sendAudioFrame:data
                          sampleCount:samples
                             channels:channelCount
                           sampleRate:rate
                             toFriend:aoi.friendNumber
                                error:nil];
        }
    };

    if (! [self.inputQueue begin:error] || ! [self.outputQueue begin:error]) {
        return NO;
    }
    else {
        return YES;
    }
}

- (BOOL)stopAudioFlow:(NSError **)error
{
    if (! [self.inputQueue stop:error] || ! [self.outputQueue stop:error]) {
        return NO;
    }

#if TARGET_OS_IPHONE
    AVAudioSession *session = [AVAudioSession sharedInstance];
    BOOL ret = [session setActive:NO error:error];
#else
    BOOL ret = YES;
#endif

    return ret;
}

- (void)provideAudioFrames:(OCTToxAVPCMData *)pcm sampleCount:(OCTToxAVSampleCount)sampleCount channels:(OCTToxAVChannels)channels sampleRate:(OCTToxAVSampleRate)sampleRate fromFriend:(OCTToxFriendNumber)friendNumber
{
    int32_t len = (int32_t)(channels * sampleCount * sizeof(int16_t));
    TPCircularBuffer *buf = [self.outputQueue getBufferPointer];
    if (buf) {
        TPCircularBufferProduceBytes(buf, pcm, len);
    }

    if ((self.outputSampleRate != sampleRate) || (self.outputNumberOfChannels != channels)) {
        // failure is logged by OCTAudioQueue.
        [self.outputQueue updateSampleRate:(Float64)sampleRate numberOfChannels:(UInt32)channels error:nil];

        self.outputSampleRate = sampleRate;
        self.outputNumberOfChannels = channels;
    }
}

- (BOOL)isAudioRunning:(NSError *__autoreleasing *)error
{
    return self.inputQueue.running && self.outputQueue.running;
}

@end
