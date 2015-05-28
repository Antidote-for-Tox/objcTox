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
-(instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    _ioUnitDescription.componentType = kAudioUnitType_Output;
    _ioUnitDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    _ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    _ioUnitDescription.componentFlags = 0;
    _ioUnitDescription.componentFlagsMask = 0;

    NewAUGraph(&_processingGraph);
    NewAUGraph(&_processingGraph);

    AUGraphAddNode(_processingGraph,
                   &_ioUnitDescription,
                   &_ioNode);

    AUGraphOpen(_processingGraph);

    AUGraphNodeInfo(_processingGraph, _ioNode, NULL, &_ioUnit);
    return self;
}

#pragma mark - Audio Controls
-(BOOL)startAudioFlow:(NSError **)error
{
    if (![self startAudioSession:error] ||
        ![self microphoneInput:YES error:error] ||
        ![self setUpStreamFormat:error] ||
        ![self initializeGraph:error] ||
        ![self startGraph:error]) {
        return NO;
    }

    return YES;
}

-(BOOL)stopAudioFlow:(NSError **)error
{
    OSStatus status = AUGraphStop(_processingGraph);
    if (status != noErr) {
        *error = [self createErrorWithCode:status
                               description:@"AUGraphStop"
                             failureReason:@"Failed to stop Graph"];
        return NO;
    }

    status = AUGraphUninitialize(_processingGraph);
    if (status != noErr) {
        *error = [self createErrorWithCode:status
                               description:@"AUGraphUninitialize"
                             failureReason:@"Failed to unintialize graph"];
        return NO;
    }

    AVAudioSession *session = [AVAudioSession sharedInstance];
    return [session setActive:NO error:error];
}

-(BOOL)microphoneInput:(BOOL)enable error:(NSError **)error
{
    UInt32 enableInput = (enable)? 1 : 0;
    OSStatus status = AudioUnitSetProperty(
                                           _ioUnit,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Input,
                                           kInputBus,
                                           &enableInput,
                                           sizeof (enableInput)
                                           );
    if (status != noErr) {
        *error = [self createErrorWithCode:status
                               description:@"Microphone Enable/Disable"
                             failureReason:@"Unable to disable/enable Mic Input"];
        return NO;
    }

    return YES;
}

-(BOOL)outputEnable:(BOOL)enable error:(NSError **)error
{

    UInt32 enableInput = (enable)? 1 : 0;
    OSStatus status = AudioUnitSetProperty(
                                           _ioUnit,
                                           kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Output,
                                           kOutputBus,
                                           &enableInput,
                                           sizeof (enableInput)
                                           );
    if (status != noErr) {
        *error = [self createErrorWithCode:status
                               description:@"Output Enable/Disable"
                             failureReason:@"Unable to disable/enable Output"];
        return NO;
    }

    return YES;
}

#pragma mark - Audio Status
-(BOOL)isAudioRunning:(NSError **)error
{
    Boolean running;
    OSStatus status = AUGraphIsRunning(_processingGraph,
                                       &running);
    if (status != noErr) {
        *error = [self createErrorWithCode:status
                               description:@"Check if Audio Graph is running"
                             failureReason:@"Failed to check if graph is running"];
    }

    return running;
}

#pragma mark - Private
-(BOOL)startAudioSession:(NSError **)error
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    bool success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                   error:error];
    if (!success) {
        return NO;
    }
    success = [session setActive:YES error:error];
    if (!success) {
        return NO;
    }

    return YES;
}

-(BOOL)setUpStreamFormat:(NSError **)error
{
    //Always initialize the fields of a new audio stream basic description structure to zero
    UInt32 bytesPerSample = sizeof (SInt32);
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

    //set the property of the ioUnit's stream format
    OSStatus status = AudioUnitSetProperty (_ioUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Output,
                                           kInputBus,
                                           &asbd,
                                           sizeof(asbd));
    if (status != noErr) {
        *error = [self createErrorWithCode:status
                               description:@"Stream Format"
                             failureReason:@"Failed to setup stream format"];
        return NO;
    }
    return YES;
}

-(BOOL)initializeGraph:(NSError **)error
{
    OSStatus status = AUGraphInitialize(_processingGraph);
    if (status != noErr) {
        *error = [self createErrorWithCode:status
                               description:@"Intialize Graph"
                             failureReason:@"Failed to initialize Graph"];
        return NO;
    } else {
        return YES;
    }
}

-(BOOL)startGraph:(NSError **)error
{
    OSStatus status = AUGraphStart(_processingGraph);
    if (status != noErr){
        *error = [self createErrorWithCode:status
                               description:@"Starting Graph"
                             failureReason:@"Failed to start Graph"];
        return NO;
    } else {
        return YES;
    }
}

- (NSError *)createErrorWithCode:(NSUInteger)code
                     description:(NSString *)description
                   failureReason:(NSString *)failureReason
{
    NSMutableDictionary *userInfo = [NSMutableDictionary new];

    if (description) {
        userInfo[NSLocalizedDescriptionKey] = description;
    }

    if (failureReason) {
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason;
    }

    return [NSError errorWithDomain:@"OCTAudioEngineError" code:code userInfo:userInfo];
}
@end
