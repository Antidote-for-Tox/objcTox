//
//  OCTAudioEngine.m
//  objcTox
//
//  Created by Chuong Vu on 5/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTAudioEngine.h"
@import AVFoundation;

static const AudioUnitElement kInputBus = 1;
static const AudioUnitElement kOutputBus = 0;

@interface OCTAudioEngine ()

@property (nonatomic, assign) AUGraph processingGraph;
@property (nonatomic, assign) AUNode ioNode;
@property (nonatomic, assign) AudioUnit ioUnit;
@property (nonatomic, assign) AudioComponentDescription ioUnitDescription;

@end

@implementation OCTAudioEngine

#pragma mark - LifeCycle
- (instancetype)init
{
    self = [super init];
    if (! self) {
        return nil;
    }

    _ioUnitDescription.componentType = kAudioUnitType_Output;
    _ioUnitDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    _ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    _ioUnitDescription.componentFlags = 0;
    _ioUnitDescription.componentFlagsMask = 0;

    NewAUGraph(&_processingGraph);

    AUGraphAddNode(_processingGraph,
                   &_ioUnitDescription,
                   &_ioNode);

    AUGraphOpen(_processingGraph);

    AUGraphNodeInfo(_processingGraph, _ioNode, NULL, &_ioUnit);
    return self;
}

#pragma mark - Audio Controls
- (BOOL)startAudioFlow:(NSError **)error
{
    return ([self startAudioSession:error] &&
            [self changeScope:OCTInput enable:YES error:error] &&
            [self setUpStreamFormat:error] &&
            [self initializeGraph:error] &&
            [self startGraph:error]);
}

- (BOOL)stopAudioFlow:(NSError **)error
{
    OSStatus status = AUGraphStop(_processingGraph);
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"AUGraphStop"
          failureReason:@"Failed to stop graph"];
        return NO;
    }

    status = AUGraphUninitialize(_processingGraph);
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"AUGraphUninitialize"
          failureReason:@"Failed to uninitialize graph"];
        return NO;
    }

    AVAudioSession *session = [AVAudioSession sharedInstance];
    return [session setActive:NO error:error];
}



- (BOOL)changeScope:(OCTAudioScope)scope enable:(BOOL)enable error:(NSError **)error
{
    UInt32 enableInput = (enable) ? 1 : 0;
    AudioUnitScope unitScope = (scope == OCTInput) ? kAudioUnitScope_Input : kAudioUnitScope_Output;

    OSStatus status = AudioUnitSetProperty(
        _ioUnit,
        kAudioOutputUnitProperty_EnableIO,
        unitScope,
        kOutputBus,
        &enableInput,
        sizeof(enableInput)
                      );
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Enable/Disable Scope"
          failureReason:@"Unable to change enable output/input on scope"];
        return NO;
    }

    return YES;

}


#pragma mark - Audio Status
- (BOOL)isAudioRunning:(NSError **)error
{
    Boolean running;
    OSStatus status = AUGraphIsRunning(_processingGraph,
                                       &running);
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Check if Audio Graph is running"
          failureReason:@"Failed to check if graph is running"];
    }

    return running;
}

#pragma mark - Private
- (BOOL)startAudioSession:(NSError **)error
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    return ([session setCategory:AVAudioSessionCategoryPlayAndRecord error:error] &&
            [session setActive:YES error:error]);
}

- (BOOL)setUpStreamFormat:(NSError **)error
{
    // Always initialize the fields of a new audio stream basic description structure to zero
    UInt32 bytesPerSample = sizeof(SInt32);
    double sampleRate = [AVAudioSession sharedInstance].sampleRate;

    AudioStreamBasicDescription asbd = {0};
    asbd.mSampleRate = sampleRate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    asbd.mChannelsPerFrame = 2;
    asbd.mBytesPerFrame = bytesPerSample;
    asbd.mBitsPerChannel = 8 * bytesPerSample;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerPacket = bytesPerSample;

    OSStatus status = AudioUnitSetProperty(_ioUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Output,
                                           kInputBus,
                                           &asbd,
                                           sizeof(asbd));
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Stream Format"
          failureReason:@"Failed to setup stream format"];
        return NO;
    }
    return YES;
}

- (BOOL)initializeGraph:(NSError **)error
{
    OSStatus status = AUGraphInitialize(_processingGraph);
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Initialize Graph"
          failureReason:@"Failed to initialize Graph"];
        return NO;
    }
    return YES;
}

- (BOOL)startGraph:(NSError **)error
{
    OSStatus status = AUGraphStart(_processingGraph);
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Starting Graph"
          failureReason:@"Failed to start Graph"];
        return NO;
    }
    return YES;
}

- (void)fillError:(NSError **)error
         withCode:(NSUInteger)code
      description:(NSString *)description
    failureReason:(NSString *)failureReason
{
    if (error) {
        NSMutableDictionary *userInfo = [NSMutableDictionary new];

        if (description) {
            userInfo[NSLocalizedDescriptionKey] = description;
        }

        if (failureReason) {
            userInfo[NSLocalizedFailureReasonErrorKey] = failureReason;
        }
        *error = [NSError errorWithDomain:@"OCTAudioEngineError" code:code userInfo:userInfo];
    }
}

@end
