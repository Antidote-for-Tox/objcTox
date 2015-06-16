//
//  OCTAudioEngine.m
//  objcTox
//
//  Created by Chuong Vu on 5/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTAudioEngine+Private.h"
#import "TPCircularBuffer.h"
@import AVFoundation;

static const AudioUnitElement kInputBus = 1;
static const AudioUnitElement kOutputBus = 0;
static const int kBufferLength = 122880;
static const int kNumberOfChannels = 2;
static const int kDefaultSampleRate = 48000;
static const NSTimeInterval kPreferredBufferDuration = .04;
static const int kSampleCount = 1920;

OSStatus (*_NewAUGraph)(AUGraph *outGraph);
OSStatus (*_AUGraphAddNode)(
    AUGraph inGraph,
    const AudioComponentDescription *inDescription,
    AUNode *outNode);
OSStatus (*_AUGraphOpen)(AUGraph inGraph);
OSStatus (*_AUGraphNodeInfo)(AUGraph inGraph,
                             AUNode inNode,
                             AudioComponentDescription *outDescription,
                             AudioUnit *outAudioUnit);

OSStatus (*_DisposeAUGraph)(AUGraph inGraph);

OSStatus (*_AUGraphStart)(AUGraph inGraph);
OSStatus (*_AUGraphStop)(AUGraph inGraph);
OSStatus (*_AUGraphInitialize)(AUGraph inGraph);
OSStatus (*_AUGraphUninitialize)(AUGraph inGraph);
OSStatus (*_AUGraphIsRunning)(AUGraph inGraph, Boolean *outIsRunning);
OSStatus (*_AudioUnitSetProperty)(AudioUnit inUnit,
                                  AudioUnitPropertyID inID,
                                  AudioUnitScope inScope,
                                  AudioUnitElement inElement,
                                  const void *inData,
                                  UInt32 inDataSize
);
OSStatus (*_AudioUnitRender)(AudioUnit inUnit,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inOutputBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData
);

@interface OCTAudioEngine ()

@property (nonatomic, assign) AUGraph processingGraph;
@property (nonatomic, assign) AUNode ioNode;
@property (nonatomic, assign) AudioUnit ioUnit;
@property (nonatomic, assign) AudioComponentDescription ioUnitDescription;
@property (nonatomic, assign) TPCircularBuffer incomingBuffer;
@property (nonatomic, assign) TPCircularBuffer outgoingBuffer;
@property (nonatomic, assign) OCTToxAVSampleRate currentAudioSampleRate;
@property (nonatomic, assign) OCTToxAVSampleRate playbackSampleRate;

@end

@implementation OCTAudioEngine

#pragma mark - LifeCycle
- (instancetype)init
{
    self = [super init];
    if (! self) {
        return nil;
    }

    [self setupCFunctions];

    _ioUnitDescription.componentType = kAudioUnitType_Output;
    _ioUnitDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    _ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    _ioUnitDescription.componentFlags = 0;
    _ioUnitDescription.componentFlagsMask = 0;

    TPCircularBufferInit(&_incomingBuffer, kBufferLength);
    TPCircularBufferInit(&_outgoingBuffer, kBufferLength);

    _NewAUGraph(&_processingGraph);

    _AUGraphAddNode(_processingGraph,
                    &_ioUnitDescription,
                    &_ioNode);

    _AUGraphOpen(_processingGraph);

    _AUGraphNodeInfo(_processingGraph, _ioNode, NULL, &_ioUnit);

    return self;
}

- (void)dealloc
{
    TPCircularBufferCleanup(&_incomingBuffer);
    TPCircularBufferCleanup(&_outgoingBuffer);

    _DisposeAUGraph(_processingGraph);
}

#pragma mark - Audio Controls
- (BOOL)startAudioFlow:(NSError **)error
{

    return ([self startAudioSession:error] &&
            [self changeScope:OCTInput enable:YES error:error] &&
            [self setupMaximumFramesPerSlice:error] &&
            [self setUpStreamFormat:error] &&
            [self registerInputCallBack:error] &&
            [self registerOutputCallBack:error] &&
            [self initializeGraph:error] &&
            [self startGraph:error]);
}

- (BOOL)stopAudioFlow:(NSError **)error
{
    OSStatus status = _AUGraphStop(self.processingGraph);
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"AUGraphStop"
          failureReason:@"Failed to stop graph"];
        return NO;
    }

    AVAudioSession *session = [AVAudioSession sharedInstance];

    return [session setActive:NO error:error];
}

- (BOOL)changeScope:(OCTAudioScope)scope enable:(BOOL)enable error:(NSError **)error
{
    UInt32 enableInput = (enable) ? 1 : 0;
    AudioUnitScope unitScope = (scope == OCTInput) ? kAudioUnitScope_Input : kAudioUnitScope_Output;
    AudioUnitElement bus = (scope == OCTInput) ? kInputBus : kOutputBus;

    OSStatus status = _AudioUnitSetProperty(
        self.ioUnit,
        kAudioOutputUnitProperty_EnableIO,
        unitScope,
        bus,
        &enableInput,
        sizeof(enableInput));

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
    OSStatus status = _AUGraphIsRunning(self.processingGraph,
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

    TPCircularBufferProduceBytes(&_incomingBuffer, pcm, len);
    if ((self.playbackSampleRate != sampleRate) && [self updatePlaybackSampleRate:sampleRate error:nil]) {
        self.playbackSampleRate = sampleRate;
    }
}

#pragma mark - Call Backs

- (BOOL)registerInputCallBack:(NSError **)error;
{
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = inputRenderCallBack;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    OSStatus status = _AudioUnitSetProperty(self.ioUnit,
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
    OSStatus status = _AudioUnitSetProperty(self.ioUnit,
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
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mNumberChannels = kNumberOfChannels;
    bufferList.mBuffers[0].mData = NULL;
    bufferList.mBuffers[0].mDataByteSize = inNumberFrames * sizeof(SInt16) * kNumberOfChannels;

    OCTAudioEngine *engine = (__bridge OCTAudioEngine *)(inRefCon);
    OSStatus status = _AudioUnitRender(engine.ioUnit,
                                       ioActionFlags,
                                       inTimeStamp,
                                       inBusNumber,
                                       inNumberFrames,
                                       &bufferList);

    TPCircularBufferProduceBytes(&engine->_outgoingBuffer,
                                 bufferList.mBuffers[0].mData,
                                 bufferList.mBuffers[0].mDataByteSize);

    int32_t availableBytesToConsume;
    void *tail = TPCircularBufferTail(&engine->_outgoingBuffer, &availableBytesToConsume);
    uint32_t minimalBytesToConsume = kSampleCount * kNumberOfChannels * sizeof(SInt16);

    int16_t cyclesToConsume = availableBytesToConsume / minimalBytesToConsume;

    for (int i = 0; i < cyclesToConsume; i++) {
        NSError *error;
        [engine.toxav sendAudioFrame:tail
                         sampleCount:kSampleCount
                            channels:kNumberOfChannels
                          sampleRate:engine.currentAudioSampleRate
                            toFriend:engine.friendNumber
                               error:&error];
        TPCircularBufferConsume(&engine->_outgoingBuffer, minimalBytesToConsume);
        tail = TPCircularBufferTail(&engine->_outgoingBuffer, &availableBytesToConsume);
    }
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

    UInt32 bytesToCopy = ioData->mBuffers[0].mDataByteSize;
    SInt16 *targetBuffer = (SInt16 *)ioData->mBuffers[0].mData;

    int32_t availableBytes;
    SInt16 *buffer = TPCircularBufferTail(&myEngine->_incomingBuffer, &availableBytes);
    UInt32 sampleCount = MIN(bytesToCopy, availableBytes);

    if (sampleCount == 0) {
        memset(targetBuffer, 0, bytesToCopy);
        return noErr;
    }
    memcpy(targetBuffer, buffer, sampleCount);
    TPCircularBufferConsume(&myEngine->_incomingBuffer, sampleCount);

    return noErr;
}


#pragma mark - Private

- (void)setupCFunctions
{
    _NewAUGraph = NewAUGraph;
    _AUGraphAddNode = AUGraphAddNode;
    _AUGraphOpen = AUGraphOpen;
    _AUGraphNodeInfo = AUGraphNodeInfo;
    _DisposeAUGraph = DisposeAUGraph;
    _AUGraphStart = AUGraphStart;
    _AUGraphStop = AUGraphStop;
    _AUGraphInitialize = AUGraphInitialize;
    _AUGraphUninitialize = AUGraphUninitialize;
    _AUGraphIsRunning = AUGraphIsRunning;
    _AudioUnitSetProperty = AudioUnitSetProperty;
    _AudioUnitRender = AudioUnitRender;
    _DisposeAUGraph = DisposeAUGraph;
}

- (BOOL)startAudioSession:(NSError **)error
{
    AVAudioSession *session = [AVAudioSession sharedInstance];

    return ([session setCategory:AVAudioSessionCategoryPlayAndRecord error:error] &&
            [session setPreferredSampleRate:kDefaultSampleRate error:error] &&
            [session setPreferredIOBufferDuration:kPreferredBufferDuration error:error] &&
            [session setActive:YES error:error]);
}

- (BOOL)setUpStreamFormat:(NSError **)error
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    self.currentAudioSampleRate = session.sampleRate;
    self.playbackSampleRate = session.sampleRate;

    UInt32 bytesPerSample = sizeof(SInt16);

    AudioStreamBasicDescription asbd = {0};
    asbd.mSampleRate = self.currentAudioSampleRate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    asbd.mChannelsPerFrame = 2;
    asbd.mBytesPerFrame = bytesPerSample * 2;
    asbd.mBitsPerChannel = 8 * bytesPerSample;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerPacket = bytesPerSample * 2;

    OSStatus status = _AudioUnitSetProperty(self.ioUnit,
                                            kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Output,
                                            kInputBus,
                                            &asbd,
                                            sizeof(asbd));
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Stream Format"
          failureReason:@"Failed to setup output stream format"];
        return NO;
    }

    status = _AudioUnitSetProperty(self.ioUnit,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   kOutputBus,
                                   &asbd,
                                   sizeof(asbd));
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Stream Format"
          failureReason:@"Failed to setup input stream format"];
        return NO;
    }
    return YES;
}

- (BOOL)initializeGraph:(NSError **)error
{
    OSStatus status = _AUGraphInitialize(self.processingGraph);
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
    OSStatus status = _AUGraphStart(self.processingGraph);
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Starting Graph"
          failureReason:@"Failed to start Graph"];
        return NO;
    }
    return YES;
}

- (BOOL)setupMaximumFramesPerSlice:(NSError **)error
{

    uint32_t maxSampleCount = kSampleCount + 1;
    OSStatus status = _AudioUnitSetProperty(self.ioUnit,
                                            kAudioUnitProperty_MaximumFramesPerSlice,
                                            kAudioUnitScope_Global,
                                            kInputBus,
                                            &maxSampleCount,
                                            sizeof(maxSampleCount));

    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Setup max frames per slice"
          failureReason:@"Failed to set max frames per slice"];
        return NO;
    }
    return YES;
}

- (BOOL)updatePlaybackSampleRate:(OCTToxAVSampleRate)rate error:(NSError **)error
{
    UInt32 bytesPerSample = sizeof(SInt16);

    AudioStreamBasicDescription asbd = {0};
    asbd.mSampleRate = rate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    asbd.mChannelsPerFrame = 2;
    asbd.mBytesPerFrame = bytesPerSample * 2;
    asbd.mBitsPerChannel = 8 * bytesPerSample;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerPacket = bytesPerSample * 2;

    OSStatus status = _AudioUnitSetProperty(self.ioUnit,
                                            kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Output,
                                            kInputBus,
                                            &asbd,
                                            sizeof(asbd));
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Stream Format"
          failureReason:@"Failed to setup output stream format"];
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
