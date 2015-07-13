//
//  OCTAudioEngine.h
//  objcTox
//
//  Created by Chuong Vu on 5/24/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTToxAV.h"

@interface OCTAudioEngine : NSObject

@property (weak, nonatomic) OCTToxAV *toxav;
@property (nonatomic, assign) OCTToxFriendNumber friendNumber;

/**
 * YES to send audio frames over to tox, otherwise NO.
 * Default is YES.
 */
@property (nonatomic, assign) BOOL enableMicrophone;

/**
 * Setup must be called once before using the audio engine.
 * @param error Pointer to error object.
 * @return YES on success, otherwise NO.
 **/
- (BOOL)setupWithError:(NSError **)error;

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
 * Send the audio to the speaker
 * @param speaker YES to send audio to speaker, NO to reset to default.
 * @param error Pointer to error object.
 * @return YES if successful override, otherwise NO.
 */
- (BOOL)routeAudioToSpeaker:(BOOL)speaker error:(NSError **)error;

/**
 * Checks if the Audio Graph is processing.
 * @param error Pointer to error object.
 * @return YES if Audio Graph is running, otherwise NO.
 */
- (BOOL)isAudioRunning:(NSError **)error;

/**
 * Provide audio data that will be placed in buffer to be played in speaker.
 * @param pcm An array of audio samples (sample_count * channels elements).
 * @param sampleCount The number of audio samples per channel in the PCM array.
 * @param channels Number of audio channels.
 * @param sampleRate Sampling rate used in this frame.
 */
- (void)provideAudioFrames:(OCTToxAVPCMData *)pcm sampleCount:(OCTToxAVSampleCount)sampleCount channels:(OCTToxAVChannels)channels sampleRate:(OCTToxAVSampleRate)sampleRate fromFriend:(OCTToxFriendNumber)friendNumber;


@end
