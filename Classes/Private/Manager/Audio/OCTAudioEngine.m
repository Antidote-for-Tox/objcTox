//
//  OCTAudioEngine.m
//  objcTox
//
//  Created by Chuong Vu on 5/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTAudioEngine.h"
@import AVFoundation;
#define kInputBus 1
#define kOutputBus 0

@interface OCTAudioEngine ()
{
    AUGraph processingGraph;

    AUNode ioNode;
    AudioUnit ioUnit;
    AudioComponentDescription ioUnitDescription;
}

@property (nonatomic, assign) double sampleRate;

@end

@implementation OCTAudioEngine

#pragma mark - LifeCycle
-(instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    ioUnitDescription.componentType = kAudioUnitType_Output;
    ioUnitDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags = 0;
    ioUnitDescription.componentFlagsMask = 0;

    NewAUGraph(&processingGraph);
    CheckStatus(NewAUGraph(&processingGraph),
                @"Failed to create AUGraph");

    CheckStatus(AUGraphAddNode(processingGraph,
                   &ioUnitDescription,
                   &ioNode),
                @"Failed to add ioNode");

    CheckStatus(AUGraphOpen(processingGraph),
                @"Failed to open graph");

    AUGraphNodeInfo(processingGraph, ioNode, NULL, &ioUnit);

    return self;
}

#pragma mark - Audio Controls
-(BOOL)startAudioFlow:(NSError **)error
{
    bool success = [self startAudioSession:error];
    if (!success) {
        return success;
    }
    success = [self microphoneInput:YES];
    if (!success) {
        return success;
    }

    [self setUpStreamFormat];

    OSStatus status = AUGraphInitialize(processingGraph);
    CheckStatus(status, @"Failed to initialize processing graph");
    if (status != noErr) {
        return NO;
    }

    AUGraphStart(processingGraph);
    CheckStatus(status, @"Failed to start processing graph");

    return (status == noErr);
}

-(BOOL)stopAudioFlow:(NSError **)error
{
    CheckStatus(AUGraphStop(processingGraph), @"Failed to stop processing graph");
    CheckStatus(AUGraphUninitialize(processingGraph), @"Unable to uninitialize graph");
    AVAudioSession *session = [AVAudioSession sharedInstance];

    bool success = [session setActive:NO error:error];

    return success;
}

-(BOOL)microphoneInput:(BOOL)enable;
{
    UInt32 enableInput = (enable)? 1 : 0;
    OSStatus status = AudioUnitSetProperty(
                                           ioUnit,
                                           kAudioOutputUnitProperty_EnableIO,//property we are changing
                                           kAudioUnitScope_Input,
                                           kInputBus,
                                           &enableInput,
                                           sizeof (enableInput)
                                           );
    CheckStatus(status, @"Unable to enable/disable input");
    return (status == noErr);
}

-(BOOL)outputEnable:(BOOL)enable error:(NSError **)error
{
    return YES;
}

#pragma mark - Audio Status
-(BOOL)isAudioRunning
{
    Boolean running;
    CheckStatus(AUGraphIsRunning(processingGraph,
                                 &running),
                @"Unable to determine if AUGraph is running");
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

    self.sampleRate = session.sampleRate;

    return YES;
}

-(void)setUpStreamFormat
{
    //Always initialize the fields of a new audio stream basic description structure to zero
    UInt32 bytesPerSample = sizeof (SInt32);

    AudioStreamBasicDescription asbd = {0};
    asbd.mSampleRate = self.sampleRate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    asbd.mChannelsPerFrame = 2;
    asbd.mBytesPerFrame = bytesPerSample;
    asbd.mBitsPerChannel = 8 * bytesPerSample;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerPacket = bytesPerSample;

    //set the property of the ioUnit's stream format
    CheckStatus(AudioUnitSetProperty(
                                           ioUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Output,
                                           kInputBus,
                                           &asbd,
                                           sizeof(asbd)),
                @"Error setting Audio Format");
}

-(BOOL)enableInputOnAudioUnit
{
    //set the property of the audio unit to accept input
    UInt32 enableInput = 1;
    OSStatus status = AudioUnitSetProperty(
                                  ioUnit,
                                  kAudioOutputUnitProperty_EnableIO,//property we are changing
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &enableInput,
                                  sizeof (enableInput)
                                  );
    CheckStatus(status, @"Unable to enable input");
    return (status == noErr);
}

static void CheckStatus(OSStatus result, NSString *errorString)
{
    if(result != noErr)
    {
        NSLog(@"%@ Error code: %d", errorString, (int)result);
    }
}
@end
