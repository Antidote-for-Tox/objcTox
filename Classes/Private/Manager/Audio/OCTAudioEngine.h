//
//  OCTAudioEngine.h
//  objcTox
//
//  Created by Chuong Vu on 5/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OCTAudioScope) {
    OCTInput,
    OCTOutput,
};

@interface OCTAudioEngine : NSObject

/**
 * Starts the Audio Processing Graph.
 * @param error Pointer to error object.
 * @return YES on success, otherwise NO.
 */
- (BOOL)startAudioFlow:(NSError **)error;

/**
 * Stops the Audio Processing Graph.
 * @param error Pointer to error object.
 * @return YES on success, otherwise NO.
 */
- (BOOL)stopAudioFlow:(NSError **)error;


/**
 * Enable or disable either output (speaker) or input (microphone).
 * @param scope AudioUnitScope
 * @param enable YES to enable, NO otherwise.
 * @param error Pointer to error object
 * @return YES on success, no otherwise.
 */
- (BOOL)changeScope:(OCTAudioScope)scope enable:(BOOL)enable error:(NSError **)error;

/**
 * Checks if the Audio Graph is processing.
 * @param error Pointer to error object.
 * @return YES if Audio Graph is running, otherwise No.
 */
- (BOOL)isAudioRunning:(NSError **)error;

/**
 * Provide audio data that will be placed in buffer to be played in speaker.
 * @param pcm An array of audio samples (sample_count * channels elements).
 * @param sample_count The number of audio samples per channel in the PCM array.
 * @param channels Number of audio channels.
 * @param sampling_rate Sampling rate used in this frame.
 */
-(void)provideAudioFrames:(const int16_t*)pcm sample_count:(size_t)sample_count channels:(uint8_t)channels sample_rate:(uint32_t)sample_rate;


@end
