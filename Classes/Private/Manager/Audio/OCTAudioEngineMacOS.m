//
//  OCTAudioEngine.m
//  objcTox
//
//  Created by Chuong Vu on 5/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//
#if ! TARGET_OS_IPHONE

#import "OCTAudioEngine+Private.h"
#import "OCTToxAV+Private.h"
#import "OCTAudioQueue.h"
#import "DDLog.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

NSString *const OCTInputDeviceDefault = @"OCTInputDeviceDefault";
NSString *const OCTOutputDeviceDefault = @"OCTOutputDeviceDefault";
NSString *const OCTOutputDeviceSpeaker = @"OCTOutputDeviceSpeaker";
NSString *const OCTInputDeviceBackCamera = @"OCTInputDeviceBackCamera";
NSString *const OCTInputDeviceFrontCamera = @"OCTInputDeviceFrontCamera";

@import AVFoundation;

@interface OCTAudioEngine ()

@property (nonatomic, strong) OCTAudioQueue *outputQueue;
@property (nonatomic, strong) OCTAudioQueue *inputQueue;

@property (nonatomic, assign) OCTToxAVSampleRate inputSampleRate;
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

- (void)setInputDeviceID:(NSString *)inputDeviceID
{
#if TARGET_OS_IPHONE
    [NSException raise:NSGenericException format:@"setInputDeviceID: is not available on iOS."];
#else
    _inputDeviceID = inputDeviceID;
    [self.inputQueue setDeviceID:inputDeviceID];
#endif
}

- (void)setOutputDeviceID:(NSString *)outputDeviceID
{
#if TARGET_OS_IPHONE
    _outputDeviceID = outputDeviceID;
    AVAudioSession *session = [AVAudioSession sharedInstance];

    AVAudioSessionPortOverride override;
    if (outputDeviceID == OCTOutputDeviceSpeaker) {
        override = AVAudioSessionPortOverrideSpeaker
    }
    else {
        override = AVAudioSessionPortOverrideNone;
    }

    // TODO: error parameters!
    [session overrideOutputAudioPort:override error:nil];
#else
    _outputDeviceID = outputDeviceID;
    [self.outputQueue setDeviceID:outputDeviceID];
#endif
}

- (BOOL)startAudioFlow:(NSError *__autoreleasing *)error
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

    // TODO: handle iOS device model
    // Note: OCTAudioQueue handles the case where the device ids are nil - in that case
    // we don't set the device explicitly, and the default is used.
    self.outputQueue = [[OCTAudioQueue alloc] initWithOutputDeviceID:self.outputDeviceID];
    self.inputQueue = [[OCTAudioQueue alloc] initWithInputDeviceID:self.inputDeviceID];

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

    [self.inputQueue begin];
    [self.outputQueue begin];

    return (_outputQueue && _inputQueue) ? YES : NO;
}

- (BOOL)stopAudioFlow:(NSError *__autoreleasing *)error
{
    [self.inputQueue stop];
    [self.outputQueue stop];

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
    TPCircularBufferProduceBytes([self.outputQueue getBufferPointer], pcm, len);

    if ((self.outputSampleRate != sampleRate) || (self.outputNumberOfChannels != channels)) {
        [self.outputQueue updateSampleRate:(Float64)sampleRate numberOfChannels:(UInt32)channels];
    }
}

- (BOOL)routeAudioToSpeaker:(BOOL)speaker error:(NSError *__autoreleasing *)error
{
    [self setOutputDeviceID:speaker ? OCTOutputDeviceSpeaker : OCTOutputDeviceDefault];
    return YES;
}

- (BOOL)isAudioRunning:(NSError *__autoreleasing *)error
{
    return self.inputQueue.running && self.outputQueue.running;
}

@end

#endif
