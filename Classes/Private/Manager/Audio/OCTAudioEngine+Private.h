//
//  OCTAudioEngine+Private.h
//  objcTox
//
//  Created by Chuong Vu on 6/7/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTAudioEngine.h"
#import "TPCircularBuffer.h"

@import AVFoundation;

extern int kBufferLength;
extern int kNumberOfChannels;
extern int kDefaultSampleRate;
extern int kSampleCount;
extern int kBitsPerByte;
extern int kFramesPerPacket;
extern int kBytesPerSample;
extern int kNumberOfAudioQueueBuffers;

@class OCTAudioQueue;
@interface OCTAudioEngine ()

#if ! TARGET_OS_IPHONE
@property (strong, nonatomic, readonly) NSString *inputDeviceID;
@property (strong, nonatomic, readonly) NSString *outputDeviceID;
#endif

@property (nonatomic, strong) OCTAudioQueue *outputQueue;
@property (nonatomic, strong) OCTAudioQueue *inputQueue;

- (void)makeQueues:(NSError **)error;

@end
