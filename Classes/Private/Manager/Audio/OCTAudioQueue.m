//
//  OCTAudioUnitWrapper.m
//  DesktopNao
//
//  Created by stal on 15/12/2015.
//  Copyright © 2015 Zodiac Labs. All rights reserved.
//

#import "OCTToxAV.h"
#import "OCTAudioQueue.h"
#import "TPCircularBuffer.h"
#import <AudioToolbox/AudioToolbox.h>

static const int kBufferLength = 384000;
static const int kNumberOfInputChannels = 2;
static const int kDefaultSampleRate = 48000;
static const int kSampleCount = 1920;
static const int kBitsPerByte = 8;
static const int kFramesPerPacket = 1;
static const UInt32 kBytesPerSample = sizeof(SInt16);

@interface OCTAudioQueue ()

@property AudioStreamBasicDescription streamFmt;
@property AudioQueueRef audioQueue;
@property (nonatomic) TPCircularBuffer buffer;
@property BOOL running;

@end

@implementation OCTAudioQueue {
    AudioQueueBufferRef _AQBuffers[2];
}

- (instancetype)initWithInputDeviceID:(NSString *)devID
{
    _streamFmt.mSampleRate = kDefaultSampleRate;
    _streamFmt.mFormatID = kAudioFormatLinearPCM;
    _streamFmt.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    _streamFmt.mChannelsPerFrame = kNumberOfInputChannels;
    _streamFmt.mBytesPerFrame = kBytesPerSample * kNumberOfInputChannels;
    _streamFmt.mBitsPerChannel = kBitsPerByte * kBytesPerSample;
    _streamFmt.mFramesPerPacket = kFramesPerPacket;
    _streamFmt.mBytesPerPacket = kBytesPerSample * kNumberOfInputChannels * kFramesPerPacket;
    _deviceID = devID;

    TPCircularBufferInit(&_buffer, kBufferLength);
    OSStatus err = AudioQueueNewInput(&_streamFmt, (void *)&InputAvailable, (__bridge void *)self, NULL, kCFRunLoopCommonModes, 0, &_audioQueue);

    if (err != 0) {
        // TPCircularBufferCleanup(&_buffer);
        return nil;
    }

    if (_deviceID) {
        AudioQueueSetProperty(self.audioQueue, kAudioQueueProperty_CurrentDevice, &_deviceID, sizeof(CFStringRef));
    }

    return self;
}

- (instancetype)initWithOutputDeviceID:(NSString *)devID
{
    _streamFmt.mSampleRate = kDefaultSampleRate;
    _streamFmt.mFormatID = kAudioFormatLinearPCM;
    _streamFmt.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    _streamFmt.mChannelsPerFrame = kNumberOfInputChannels;
    _streamFmt.mBytesPerFrame = kBytesPerSample * kNumberOfInputChannels;
    _streamFmt.mBitsPerChannel = kBitsPerByte * kBytesPerSample;
    _streamFmt.mFramesPerPacket = kFramesPerPacket;
    _streamFmt.mBytesPerPacket = kBytesPerSample * kNumberOfInputChannels * kFramesPerPacket;
    _deviceID = devID;

    TPCircularBufferInit(&_buffer, kBufferLength);
    OSStatus err = AudioQueueNewOutput(&_streamFmt, (void *)&FillOutputBuffer, (__bridge void *)self, NULL, kCFRunLoopCommonModes, 0, &_audioQueue);

    if (err != 0) {
        // TPCircularBufferCleanup(&_buffer);
        return nil;
    }

    if (_deviceID) {
        AudioQueueSetProperty(self.audioQueue, kAudioQueueProperty_CurrentDevice, &_deviceID, sizeof(CFStringRef));
    }

    return self;
}

- (void)dealloc
{
    AudioQueueDispose(self.audioQueue, true);
    TPCircularBufferCleanup(&_buffer);
}

- (void)begin
{
    for (int i = 0; i < 2; ++i) {
        AudioQueueAllocateBuffer(self.audioQueue, kBytesPerSample * kNumberOfInputChannels, &(_AQBuffers[i]));
        AudioQueueEnqueueBuffer(self.audioQueue, _AQBuffers[i], 0, NULL);
    }

    AudioQueueStart(self.audioQueue, NULL);
    self.running = YES;
}

- (void)stop
{
    AudioQueueStop(self.audioQueue, true);

    for (int i = 0; i < 2; ++i) {
        AudioQueueFreeBuffer(self.audioQueue, _AQBuffers[i]);
    }

    self.running = NO;
}

- (TPCircularBuffer *)getBufferPointer
{
    return &_buffer;
}

- (void)setDeviceID:(NSString *)deviceID
{
    // we need to pause the queue for a sec
    [self stop];
    OSStatus ok = AudioQueueSetProperty(self.audioQueue, kAudioQueueProperty_CurrentDevice, &deviceID, sizeof(CFStringRef));

    if (ok != 0) {
        NSLog(@"OCTAudioQueue setDeviceID: Error while live setting device to '%@': %d", deviceID, ok);
    }
    else {
        _deviceID = deviceID;
    }

    [self begin];
}

- (void)updateSampleRate:(Float64)sampleRate numberOfChannels:(UInt32)numberOfChannels
{
    AudioQueueSetProperty(self.audioQueue, kAudioQueueDeviceProperty_SampleRate, &sampleRate, sizeof(Float64));
    AudioQueueSetProperty(self.audioQueue, kAudioQueueDeviceProperty_NumberChannels, &numberOfChannels, sizeof(UInt32));
}

// avoid annoying bridge cast in 1st param!
static void InputAvailable(OCTAudioQueue *__unsafe_unretained context,
                           AudioQueueRef inAQ,
                           AudioQueueBufferRef inBuffer,
                           const AudioTimeStamp *inStartTime,
                           UInt32 inNumPackets,
                           const AudioStreamPacketDescription *inPacketDesc)
{
    TPCircularBufferProduceBytes(&(context->_buffer),
                                 inBuffer->mAudioData,
                                 inBuffer->mAudioDataByteSize);

    int32_t availableBytesToConsume;
    void *tail = TPCircularBufferTail(&context->_buffer, &availableBytesToConsume);
    int32_t minimalBytesToConsume = kSampleCount * kNumberOfInputChannels * sizeof(SInt16);
    int32_t cyclesToConsume = availableBytesToConsume / minimalBytesToConsume;

    for (int32_t i = 0; i < cyclesToConsume; i++) {
        context.sendDataBlock(tail, kSampleCount, kDefaultSampleRate, kNumberOfInputChannels);
        TPCircularBufferConsume(&context->_buffer, minimalBytesToConsume);
        tail = TPCircularBufferTail(&context->_buffer, &availableBytesToConsume);
    }

    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
}

static void FillOutputBuffer(OCTAudioQueue *__unsafe_unretained context,
                             AudioQueueRef inAQ,
                             AudioQueueBufferRef inBuffer)
{
    int32_t targetBufferSize = inBuffer->mAudioDataByteSize;
    SInt16 *targetBuffer = inBuffer->mAudioData;

    int32_t availableBytes;
    SInt16 *buffer = TPCircularBufferTail(&context->_buffer, &availableBytes);

    if (availableBytes < targetBufferSize) {
        memset(targetBuffer, 0, targetBufferSize);
    }
    else {
        memcpy(targetBuffer, buffer, targetBufferSize);
        TPCircularBufferConsume(&context->_buffer, targetBufferSize);
    }

    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
}

@end
