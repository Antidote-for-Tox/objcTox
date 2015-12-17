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

- (BOOL)startAudioFlow:(NSError *__autoreleasing *)error
{
    // TODO: use user-supplied devices!!
    // TODO: handle iOS device model
    self.outputQueue = [[OCTAudioQueue alloc] initWithOutputDeviceID:@"AppleHDAEngineOutput:1B,0,1,2:0"];
    self.inputQueue = [[OCTAudioQueue alloc] initWithInputDeviceID:@"SoundflowerEngine:0"];

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

    return YES;
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
    return YES;
}

- (BOOL)isAudioRunning:(NSError *__autoreleasing *)error
{
    return self.inputQueue.running && self.outputQueue.running;
}

@end

#endif
