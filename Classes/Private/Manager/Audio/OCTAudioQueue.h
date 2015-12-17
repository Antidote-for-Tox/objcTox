//
//  OCTAudioUnitWrapper.h
//  DesktopNao
//
//  Created by stal on 15/12/2015.
//  Copyright © 2015 Zodiac Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TPCircularBuffer.h"

/* no idea what to name this thing, so here it is */
@interface OCTAudioQueue : NSObject

@property (strong, nonatomic) NSString *deviceID;
@property (strong, nonatomic) void (^sendDataBlock)(void *, OCTToxAVSampleCount, OCTToxAVSampleRate, OCTToxAVChannels);
@property (assign, nonatomic, readonly) BOOL running;

- (instancetype)initWithInputDeviceID:(NSString *)devID;
- (instancetype)initWithOutputDeviceID:(NSString *)devID;

- (TPCircularBuffer *)getBufferPointer;
- (void)updateSampleRate:(Float64)sampleRate numberOfChannels:(UInt32)numberOfChannels;

- (void)begin;
- (void)stop;

@end
