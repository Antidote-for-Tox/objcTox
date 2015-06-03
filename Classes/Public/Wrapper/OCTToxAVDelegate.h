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
 * Audio bitrate has changed.
 * @param bitrate The bitrate in Kb/sec.
 * @param stable Is the stream stable enough to keep the bit rate.
 * Upon successful, non forceful, bit rate change, this is set to
 * true and 'bit_rate' is set to new bit rate.
 * The stable is set to false with bit_rate set to the unstable
 * bit rate when either current stream is unstable with said bit rate
 * or the non forceful change failed.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)toxAV:(OCTToxAV *)toxAV audioBitRateChanged:(OCTToxAVAudioBitRate)bitrate stable:(BOOL)stable friendNumber:(OCTToxFriendNumber)friendNumber;

/**
 * Video bitrate has changed.
 * @param bitrate The bitrate in Kb/sec.
 * @param stable Is the stream stable enough to keep the bit rate.
 * Upon successful, non forceful, bit rate change, this is set to
 * true and 'bit_rate' is set to new bit rate.
 * The stable is set to false with bit_rate set to the unstable
 * bit rate when either current stream is unstable with said bit rate
 * or the non forceful change failed.
 * @param friendNumber Friend number of appropriate friend.
 */
- (void)toxAV:(OCTToxAV *)toxAV videoBitRateChanged:(OCTToxAVVideoBitRate)bitrate friendNumber:(OCTToxFriendNumber)friendNumber stable:(BOOL)stable;

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
 *          A = MAX(width, abs(astride)) * height.
 * @param yStride
 * @param uStride
 * @param vStride
 * @param aStride Strides data. Strides represent padding for each plane
 *                that may or may not be present. You must handle strides in
 *                your image processing code. Strides are negative if the
 *                image is bottom-up hence why you MUST abs() it when
 *                calculating plane buffer size.
 * @param friendNumber The friend number of the friend who sent an audio frame.
 */

- (void)   toxAV:(OCTToxAV *)toxAV
           width:(OCTToxAVVideoWidth)width height:(OCTToxAVVideoHeight)height
          yPlane:(OCTToxAVPlaneData *)yPlane uPlane:(OCTToxAVPlaneData *)uPlane
          vPlane:(OCTToxAVPlaneData *)vPlane aPlane:(OCTToxAVPlaneData *)aPlane
         yStride:(OCTToxAVStrideData)yStride uStride:(OCTToxAVStrideData)uStride
         vStride:(OCTToxAVStrideData)vStride aStride:(OCTToxAVStrideData)aStride
    friendNumber:(OCTToxFriendNumber)friendNumber;

@end
