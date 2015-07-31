//
//  OCTVideoEngine.h
//  objcTox
//
//  Created by Chuong Vu on 6/19/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "OCTToxAV.h"

@interface OCTVideoEngine : NSObject

@property (weak, nonatomic) OCTToxAV *toxav;
@property (nonatomic, assign) OCTToxFriendNumber friendNumber;

/**
 * This must be called prior to using the video session.
 * @param error Pointer to error object.
 * @return YES if successful, otherwise NO.
 */
- (BOOL)setupWithError:(NSError **)error;

/**
 * Process incoming video frames.
 * Set to YES to process video, otherwise NO
 * to ignore the incoming frames in receiveVideoFrameWithWidth...
 */
@property (nonatomic, assign) BOOL processIncomingVideo;

/**
 * Start the vidio session.
 */
- (void)startVideoSession;

/**
 * Stop the video session.
 */
- (void)stopVideoSession;

/**
 * Indicates if the video session is running.
 * @return YES if running, NO otherwise.
 */
- (BOOL)isVideoSessionRunning;

/**
 * View controller with video.
 */

/**
 * Layer of the preview video.
 */
- (CALayer *)videoCallPreview;

/**
 * Provide video frames to video engine to process.
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
- (void)receiveVideoFrameWithWidth:(OCTToxAVVideoWidth)width
                           height:(OCTToxAVVideoHeight)height
                           yPlane:(OCTToxAVPlaneData *)yPlane
                           uPlane:(OCTToxAVPlaneData *)uPlane
                           vPlane:(OCTToxAVPlaneData *)vPlane
                          yStride:(OCTToxAVStrideData)yStride
                          uStride:(OCTToxAVStrideData)uStride
                         vStride:(OCTToxAVStrideData)vStride
                     friendNumber:(OCTToxFriendNumber)friendNumber;
@end
