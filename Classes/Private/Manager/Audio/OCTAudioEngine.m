//
//  OCTAudioEngine.m
//  objcTox
//
//  Created by Chuong Vu on 5/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTAudioEngine+Private.h"
#import "OCTToxAV+Private.h"
#import "DDLog.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

@import AVFoundation;

static const AudioUnitElement kInputBus = 1;
static const AudioUnitElement kOutputBus = 0;
static const int kBufferLength = 16384;
static const int kNumberOfInputChannels = 2;
static const int kDefaultSampleRate = 48000;
static const int kSampleCount = 1920;
static const int kBitsPerByte = 8;
static const int kFramesPerPacket = 1;

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
@property (nonatomic, assign) TPCircularBuffer outputBuffer;
@property (nonatomic, assign) TPCircularBuffer inputBuffer;
@property (nonatomic, assign) OCTToxAVSampleRate inputSampleRate;
@property (nonatomic, assign) OCTToxAVSampleRate outputSampleRate;
@property (nonatomic, assign) dispatch_once_t setupOnceToken;

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

    [self setupCFunctions];

    _ioUnitDescription.componentType = kAudioUnitType_Output;
    _ioUnitDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    _ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    _ioUnitDescription.componentFlags = 0;
    _ioUnitDescription.componentFlagsMask = 0;

    TPCircularBufferInit(&_outputBuffer, kBufferLength);
    TPCircularBufferInit(&_inputBuffer, kBufferLength);

    _enableMicrophone = YES;

    return self;
}

- (void)dealloc
{
    TPCircularBufferCleanup(&_outputBuffer);
    TPCircularBufferCleanup(&_inputBuffer);
}

- (BOOL)setupGraphWithError:(NSError **)error
{
    _NewAUGraph(&_processingGraph);

    _AUGraphAddNode(self.processingGraph,
                    &_ioUnitDescription,
                    &_ioNode);

    _AUGraphOpen(_processingGraph);

    _AUGraphNodeInfo(_processingGraph, _ioNode, NULL, &_ioUnit);

    return ([self enableInputScope:error] &&
            [self registerInputCallBack:error] &&
            [self registerOutputCallBack:error] &&
            [self initializeGraph:error]);
}

#pragma mark - Audio Controls
- (BOOL)startAudioFlow:(NSError **)error
{
    return ([self setupGraphWithError:error] &&
            [self startAudioSession:error] &&
            [self setUpStreamFormat:error] &&
            [self startGraph:error]);
}

- (BOOL)stopAudioFlow:(NSError **)error
{

    OSStatus status = _AUGraphStop(self.processingGraph);

    AUGraphClose(self.processingGraph);

    DisposeAUGraph(self.processingGraph);

    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"AUGraphStop"
          failureReason:@"Failed to stop graph"];
        return NO;
    }

    TPCircularBufferClear(&_outputBuffer);
    TPCircularBufferClear(&_inputBuffer);

#if TARGET_OS_IPHONE
    AVAudioSession *session = [AVAudioSession sharedInstance];

    return [session setActive:NO error:error];
#else
#warning TODO audio OSX
    return NO;
#endif
}

- (BOOL)routeAudioToSpeaker:(BOOL)speaker error:(NSError **)error;
{
#if TARGET_OS_IPHONE
    AVAudioSession *session = [AVAudioSession sharedInstance];

    AVAudioSessionPortOverride override = (speaker) ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;

    return [session overrideOutputAudioPort:override error:error];
#else
#warning TODO audio OSX
    return NO;
#endif
}

#pragma mark - Audio Status
- (BOOL)isAudioRunning:(NSError **)error
{
    Boolean running = false;
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
- (void)provideAudioFrames:(OCTToxAVPCMData *)pcm
               sampleCount:(OCTToxAVSampleCount)sampleCount
                  channels:(OCTToxAVChannels)channels
                sampleRate:(OCTToxAVSampleRate)sampleRate
                fromFriend:(OCTToxFriendNumber)friendNumber
{
    if (self.friendNumber != friendNumber) {
        return;
    }

    int32_t len = (int32_t)(channels * sampleCount * sizeof(int16_t));

    TPCircularBufferProduceBytes(&_outputBuffer, pcm, len);

    if ((self.outputSampleRate != sampleRate) || (self.outputNumberOfChannels != channels)) {
        NSError *error;
        if (! [self updateOutputSampleRate:sampleRate channels:channels error:&error]) {
            DDLogWarn(@"%@, error updateOutputSampleRate:%@", self, error);
        }
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


OSStatus inputRenderCallBack(void *inRefCon,
                             AudioUnitRenderActionFlags  *ioActionFlags,
                             const AudioTimeStamp    *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData)
{
    OCTAudioEngine *engine = (__bridge OCTAudioEngine *)(inRefCon);

    if (! engine.enableMicrophone) {
        return noErr;
    }

    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mNumberChannels = kNumberOfInputChannels;
    bufferList.mBuffers[0].mData = NULL;
    bufferList.mBuffers[0].mDataByteSize = inNumberFrames * sizeof(SInt16) * kNumberOfInputChannels;

    OSStatus status = _AudioUnitRender(engine.ioUnit,
                                       ioActionFlags,
                                       inTimeStamp,
                                       inBusNumber,
                                       inNumberFrames,
                                       &bufferList);

    TPCircularBufferProduceBytes(&engine->_inputBuffer,
                                 bufferList.mBuffers[0].mData,
                                 bufferList.mBuffers[0].mDataByteSize);

    int32_t availableBytesToConsume;
    void *tail = TPCircularBufferTail(&engine->_inputBuffer, &availableBytesToConsume);
    int32_t minimalBytesToConsume = kSampleCount * kNumberOfInputChannels * sizeof(SInt16);

    int32_t cyclesToConsume = availableBytesToConsume / minimalBytesToConsume;

    for (int32_t i = 0; i < cyclesToConsume; i++) {
        NSError *error;
        [engine.toxav sendAudioFrame:tail
                         sampleCount:kSampleCount
                            channels:kNumberOfInputChannels
                          sampleRate:engine.inputSampleRate
                            toFriend:engine.friendNumber
                               error:&error];
        TPCircularBufferConsume(&engine->_inputBuffer, minimalBytesToConsume);
        tail = TPCircularBufferTail(&engine->_inputBuffer, &availableBytesToConsume);
    }
    return status;
}

OSStatus outputRenderCallBack(void *inRefCon,
                              AudioUnitRenderActionFlags *ioActionFlags,
                              const AudioTimeStamp *inTimeStamp,
                              UInt32 inBusNumber,
                              UInt32 inNumberFrames,
                              AudioBufferList *ioData)
{
    OCTAudioEngine *myEngine = (__bridge OCTAudioEngine *)inRefCon;

    int32_t targetBufferSize = ioData->mBuffers[0].mDataByteSize;
    SInt16 *targetBuffer = (SInt16 *)ioData->mBuffers[0].mData;

    int32_t availableBytes;
    SInt16 *buffer = TPCircularBufferTail(&myEngine->_outputBuffer, &availableBytes);

    if (availableBytes < targetBufferSize) {
        memset(targetBuffer, 0, targetBufferSize);
        return noErr;
    }
    memcpy(targetBuffer, buffer, targetBufferSize);
    TPCircularBufferConsume(&myEngine->_outputBuffer, targetBufferSize);

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
#if TARGET_OS_IPHONE
    AVAudioSession *session = [AVAudioSession sharedInstance];

    return ([session setCategory:AVAudioSessionCategoryPlayAndRecord error:error] &&
            [session setPreferredSampleRate:kDefaultSampleRate error:error] &&
            [session setMode:AVAudioSessionModeVoiceChat error:error] &&
            [session setActive:YES error:error]);
#else
#warning TODO audio OSX
    return NO;
#endif
}

- (BOOL)setUpStreamFormat:(NSError **)error
{
#if TARGET_OS_IPHONE
    AVAudioSession *session = [AVAudioSession sharedInstance];
    self.inputSampleRate = (OCTToxAVSampleRate)session.sampleRate;
    self.outputSampleRate = (OCTToxAVSampleRate)session.sampleRate;
#else
#warning TODO audio OSX
#endif

    UInt32 bytesPerSample = sizeof(SInt16);

    AudioStreamBasicDescription asbd = {0, 0, 0, 0, 0, 0, 0, 0, 0};
    asbd.mSampleRate = self.inputSampleRate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    asbd.mChannelsPerFrame = kNumberOfInputChannels;
    asbd.mBytesPerFrame = bytesPerSample * kNumberOfInputChannels;
    asbd.mBitsPerChannel = kBitsPerByte * bytesPerSample;
    asbd.mFramesPerPacket = kFramesPerPacket;
    asbd.mBytesPerPacket = bytesPerSample * kNumberOfInputChannels;

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

- (void)setFriendNumber:(OCTToxFriendNumber)friendNumber
{
    _friendNumber = friendNumber;

    TPCircularBufferClear(&_inputBuffer);
    TPCircularBufferClear(&_outputBuffer);
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

- (BOOL)updateOutputSampleRate:(OCTToxAVSampleRate)rate channels:(OCTToxAVChannels)channels error:(NSError **)error
{
    DDLogVerbose(@"%@ updateOutputSampleRate:%u channels:%u", self, rate, channels);

    UInt32 bytesPerSample = sizeof(SInt16);

    AudioStreamBasicDescription asbd = {0, 0, 0, 0, 0, 0, 0, 0, 0};
    asbd.mSampleRate = rate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    asbd.mChannelsPerFrame = channels;
    asbd.mBytesPerFrame = bytesPerSample * channels;
    asbd.mBitsPerChannel = kBitsPerByte * bytesPerSample;
    asbd.mFramesPerPacket = kFramesPerPacket;
    asbd.mBytesPerPacket = bytesPerSample * channels;

    OSStatus status = _AudioUnitSetProperty(self.ioUnit,
                                            kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Input,
                                            kOutputBus,
                                            &asbd,
                                            sizeof(asbd));
    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"Stream Format"
          failureReason:@"Failed to setup output stream format"];
        return NO;
    }

    self.outputSampleRate = rate;
    self.outputNumberOfChannels = channels;

    return YES;
}

- (BOOL)enableInputScope:(NSError **)error
{
    UInt32 enableInput = 1;
    OSStatus status =  _AudioUnitSetProperty(
        _ioUnit,
        kAudioOutputUnitProperty_EnableIO,
        kAudioUnitScope_Input,
        kInputBus,
        &enableInput,
        sizeof(enableInput));

    if (status != noErr) {
        [self fillError:error
               withCode:status
            description:@"EnableIO of input scope"
          failureReason:@"Unable to enable input scope"];
        return NO;
    }

    return YES;
}


- (BOOL)fillError:(NSError **)error
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

    return YES;
}

@end
