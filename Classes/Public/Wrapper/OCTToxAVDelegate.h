//
//  OCTToxAVDelegate.h
//  objcTox
//
//  Created by Chuong Vu on 6/3/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTToxAVConstants.h"
#import "OCTToxConstants.h"

@class OCTToxAV;

/**
 * All delegate methods will be called on main thread.
 */
@protocol OCTToxAVDelegate <NSObject>

@optional

/**
 * Receiving call from friend.
 * @param audio YES audio is enabled. NO otherwise.
 * @param video YES video is enabled. NO otherwise.
 * @param friendNumber Friend number who is calling.
 */
- (void)toxAV:(OCTToxAV *)toxAV receiveCallAudioEnabled:(BOOL)audio videoEnabled:(BOOL)video friendNumber:(OCTToxFriendNumber)friendNumber;

/**
 * Call state has changed.
 * @param state The new state.
 * @param friendNumber Friend number whose state has changed.
 */
- (void)toxAV:(OCTToxAV *)toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:(OCTToxFriendNumber)friendNumber;

/**
 * The event is triggered when the network becomes too saturated for
 * current bit rates at which point core suggests new bit rates.
 * @param friendNumber The friend number of the friend for which to set the
 * bit rate.
 * @param audio_bit_rate Suggested maximum audio bit rate in Kb/sec.
 * @param video_bit_rate Suggested maximum video bit rate in Kb/sec.
 */
- (void)   toxAV:(OCTToxAV *)toxAV bitrateStatusForFriendNumber:(OCTToxFriendNumber)friendNumber
    audioBitRate:(OCTToxAVAudioBitRate)audioBitrate
    videoBitRate:(OCTToxAVVideoBitRate)videoBitrate;

/**
 * Received audio frame from friend.
 * @param pcm An array of audio samples (sample_count * channels elements).
 * @param sampleCount The number of audio samples per channel in the PCM array.
 * @param channels Number of audio channels.
 * @param sampleRate Sampling rate used in this frame.
 * @param friendNumber The friend number of the friend who sent an audio frame.
 */

- (void)   toxAV:(OCTToxAV *)toxAV
    receiveAudio:(OCTToxAVPCMData *)pcm
     sampleCount:(OCTToxAVSampleCount)sampleCount
        channels:(OCTToxAVChannels)channels
      sampleRate:(OCTToxAVSampleRate)sampleRate
    friendNumber:(OCTToxFriendNumber)friendNumber;

/**
 * Received video frame from friend.
 * @param width Width of the frame in pixels.
 * @param height Height of the frame in pixels.
 * @param yPlane
 * @param uPlane
 * @param vPlane Plane data.
 *          The size of plane data is derived from width and height where
 *          Y = MAX(width, abs(ystride)) * height,
 *          U = MAX(width/2, abs(ustride)) * (height/2) and
 *          V = MAX(width/2, abs(vstride)) * (height/2).
 * @param yStride
 * @param uStride
 * @param vStride Strides data. Strides represent padding for each plane
 *                that may or may not be present. You must handle strides in
 *                your image processing code. Strides are negative if the
 *                image is bottom-up hence why you MUST abs() it when
 *                calculating plane buffer size.
 * @param friendNumber The friend number of the friend who sent an audio frame.
 */

- (void)                 toxAV:(OCTToxAV *)toxAV
    receiveVideoFrameWithWidth:(OCTToxAVVideoWidth)width height:(OCTToxAVVideoHeight)height
                        yPlane:(OCTToxAVPlaneData *)yPlane uPlane:(OCTToxAVPlaneData *)uPlane
                        vPlane:(OCTToxAVPlaneData *)vPlane
                       yStride:(OCTToxAVStrideData)yStride uStride:(OCTToxAVStrideData)uStride
                       vStride:(OCTToxAVStrideData)vStride
                  friendNumber:(OCTToxFriendNumber)friendNumber;

@end
