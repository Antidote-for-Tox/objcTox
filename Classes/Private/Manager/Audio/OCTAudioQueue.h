//
//  OCTAudioUnitWrapper.h
//  DesktopNao
//
//  Created by stal on 15/12/2015.
//  Copyright © 2015 Zodiac Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TPCircularBuffer.h"

@import AudioToolbox;

#pragma mark - C declarations

extern OSStatus (*_AudioQueueAllocateBuffer)( AudioQueueRef inAQ, UInt32 inBufferByteSize, AudioQueueBufferRef  *outBuffer );
extern OSStatus (*_AudioQueueDispose)( AudioQueueRef inAQ, Boolean inImmediate );
extern OSStatus (*_AudioQueueEnqueueBuffer)( AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, UInt32 inNumPacketDescs, const AudioStreamPacketDescription *inPacketDescs );
extern OSStatus (*_AudioQueueFreeBuffer)( AudioQueueRef inAQ, AudioQueueBufferRef inBuffer );
extern OSStatus (*_AudioQueueNewInput)( const AudioStreamBasicDescription *inFormat, AudioQueueInputCallback inCallbackProc, void *inUserData, CFRunLoopRef inCallbackRunLoop, CFStringRef inCallbackRunLoopMode, UInt32 inFlags, AudioQueueRef  *outAQ );
extern OSStatus (*_AudioQueueNewOutput)( const AudioStreamBasicDescription *inFormat, AudioQueueOutputCallback inCallbackProc, void *inUserData, CFRunLoopRef inCallbackRunLoop, CFStringRef inCallbackRunLoopMode, UInt32 inFlags, AudioQueueRef  *outAQ );
extern OSStatus (*_AudioQueueSetProperty)( AudioQueueRef inAQ, AudioQueuePropertyID inID, const void *inData, UInt32 inDataSize );
extern OSStatus (*_AudioQueueStart)( AudioQueueRef inAQ, const AudioTimeStamp *inStartTime );
extern OSStatus (*_AudioQueueStop)( AudioQueueRef inAQ, Boolean inImmediate );
extern OSStatus (*_AudioObjectGetPropertyData)( AudioObjectID inObjectID, const AudioObjectPropertyAddress *inAddress,                           UInt32 inQualifierDataSize,                           const void *inQualifierData,                           UInt32 *ioDataSize,                           void *outData);

/* no idea what to name this thing, so here it is */
@interface OCTAudioQueue : NSObject

@property (strong, nonatomic, readonly) NSString *deviceID;
@property (strong, nonatomic) void (^sendDataBlock)(void *, OCTToxAVSampleCount, OCTToxAVSampleRate, OCTToxAVChannels);
@property (assign, nonatomic, readonly) BOOL running;

- (instancetype)initWithInputDeviceID:(NSString *)devID;
- (instancetype)initWithOutputDeviceID:(NSString *)devID;

- (TPCircularBuffer *)getBufferPointer;
- (BOOL)updateSampleRate:(Float64)sampleRate numberOfChannels:(UInt32)numberOfChannels error:(NSError **)err;
- (BOOL)setDeviceID:(NSString *)deviceID error:(NSError **)err;

- (BOOL)begin:(NSError **)error;
- (BOOL)stop:(NSError **)error;

@end
