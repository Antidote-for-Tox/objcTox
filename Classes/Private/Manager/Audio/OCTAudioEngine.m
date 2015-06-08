//
//  OCTAudioEngine.m
//  objcTox
//
//  Created by Chuong Vu on 5/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTAudioEngine.h"
#import "TPCircularBuffer.h"
@import AVFoundation;

static const AudioUnitElement kInputBus = 1;
static const AudioUnitElement kOutputBus = 0;
static const int kBufferLength = 1024;

@interface OCTAudioEngine ()

@property (nonatomic, assign) AUGraph processingGraph;
@property (nonatomic, assign) AUNode ioNode;
@property (nonatomic, assign) AudioUnit ioUnit;
@property (nonatomic, assign) AudioComponentDescription ioUnitDescription;
@property (nonatomic, assign) TPCircularBuffer buffer;

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

    TPCircularBufferInit(&_buffer, kBufferLength);

    NewAUGraph(&_processingGraph);

    AUGraphAddNode(_processingGraph,
                   &_ioUnitDescription,
                   &_ioNode);

    AUGraphOpen(_processingGraph);

    AUGraphNodeInfo(_processingGraph, _ioNode, NULL, &_ioUnit);
    return self;
}

- (void)dealloc
{
    TPCircularBufferCleanup(&_buffer);
    DisposeAUGraph(_processingGraph);
}

#pragma mark - Audio Controls
- (BOOL)startAudioFlow:(NSError **)error
{
    return ([self startAudioSession:error] &&
            [self changeScope:OCTInput enable:YES error:error] &&
            [self setUpStreamFormat:error] &&
            [self registerInputCallBack:error] &&
            [self registerOutputCallBack:error] &&
            [self initializeGraph:error] &&
            [self startGraph:error]);
}

- (BOOL)stopAudioFlow:(NSError **)error
{
    OSStatus status = AUGraphStop(self.processingGraph);
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"AUGraphStop"
          failureReason:@"Failed to stop graph"];
        return NO;
    }

    status = AUGraphUninitialize(self.processingGraph);
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
        self.ioUnit,
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
    OSStatus status = AUGraphIsRunning(self.processingGraph,
                                       &running);
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Check if Audio Graph is running"
          failureReason:@"Failed to check if graph is running"];
    }

    return running;
}

#pragma mark - Buffer Management
- (void)provideAudioFrames:(const int16_t *)pcm sampleCount:(size_t)sampleCount channels:(uint8_t)channels sampleRate:(uint32_t)sampleRate
{
    int32_t len = (int32_t)(channels * sampleCount * sizeof(int16_t));
    TPCircularBufferProduceBytes(&_buffer, pcm, len);
}

#pragma mark - Call Backs

- (BOOL)registerInputCallBack:(NSError **)error;
{
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = inputRenderCallBack;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    OSStatus status = AudioUnitSetProperty(self.ioUnit,
                                           kAudioOutputUnitProperty_SetInputCallback,
                                           kAudioUnitScope_Global,
                                           kInputBus,
                                           &callbackStruct,
                                           sizeof(callbackStruct));

    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Registering Input Callback"
          failureReason:@"Failed to register input callback"];
        return NO;
    }
    return YES;
}

- (BOOL)registerOutputCallBack:(NSError **)error;
{
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = outputRenderCallBack;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    OSStatus status = AudioUnitSetProperty(self.ioUnit,
                                           kAudioUnitProperty_SetRenderCallback,
                                           kAudioUnitScope_Global,
                                           kOutputBus,
                                           &callbackStruct,
                                           sizeof(callbackStruct));

    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Registering output Callback"
          failureReason:@"Failed to register output callback"];
        return NO;
    }
    return YES;
}


static OSStatus inputRenderCallBack(void *inRefCon,
                                    AudioUnitRenderActionFlags  *ioActionFlags,
                                    const AudioTimeStamp    *inTimeStamp,
                                    UInt32 inBusNumber,
                                    UInt32 inNumberFrames,
                                    AudioBufferList *ioData)
{

    AudioBufferList bufferList;

    OCTAudioEngine *engine = (__bridge OCTAudioEngine *)(inRefCon);
    OSStatus status = AudioUnitRender(engine.ioUnit,
                                      ioActionFlags,
                                      inTimeStamp,
                                      inBusNumber,
                                      inNumberFrames,
                                      &bufferList);
    // To Do: Call [OCTToxAV sendAudioFrames...]
    return status;
}

static OSStatus outputRenderCallBack(void *inRefCon,
                                     AudioUnitRenderActionFlags *ioActionFlags,
                                     const AudioTimeStamp *inTimeStamp,
                                     UInt32 inBusNumber,
                                     UInt32 inNumberFrames,
                                     AudioBufferList *ioData)
{
    OCTAudioEngine *myEngine = (__bridge OCTAudioEngine *)inRefCon;

    int bytesToCopy = ioData->mBuffers[0].mDataByteSize;
    SInt16 *targetBuffer = (SInt16 *)ioData->mBuffers[0].mData;

    int32_t availableBytes;
    SInt16 *buffer = TPCircularBufferTail(&myEngine->_buffer, &availableBytes);
    int32_t sampleCount = MIN(bytesToCopy, availableBytes);
    memcpy(targetBuffer, buffer, sampleCount);
    TPCircularBufferConsume(&myEngine->_buffer, sampleCount);

    return noErr;
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
    UInt32 bytesPerSample = sizeof(SInt32);
    double sampleRate = [AVAudioSession sharedInstance].sampleRate;

    AudioStreamBasicDescription asbd = {0};
    asbd.mSampleRate = sampleRate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    asbd.mChannelsPerFrame = 2;
    asbd.mBytesPerFrame = bytesPerSample;
    asbd.mBitsPerChannel = 8 * bytesPerSample;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerPacket = bytesPerSample;

    OSStatus status = AudioUnitSetProperty(self.ioUnit,
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
    OSStatus status = AUGraphInitialize(self.processingGraph);
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
    OSStatus status = AUGraphStart(self.processingGraph);
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
