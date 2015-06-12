//
//  OCTSubmanagerCalls.h
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OCTChat.h"
#import "OCTArray.h"
#import "OCTCallsContainer.h"
@class OCTSubmanagerCalls;
@class OCTToxAV;
@class OCTCall;

@protocol OCTSubmanagerCallDelegate <NSObject>

/**
 * Delegate for when we receive a call.
 **/
- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager receiveCall:(OCTCall *)call audioEnabled:(BOOL)audioEnabled videoEnabled:(BOOL)videoEnabled;

/**
 * Audio bitrate has changed
 **/
- (void)callSubmanager:(OCTSubmanagerCalls *)callSubmanager audioBitRateChanged:(OCTToxAVAudioBitRate)bitRate stable:(BOOL)stable forCall:(OCTCall *)call;

@end

@interface OCTSubmanagerCalls : NSObject

@property (weak, nonatomic) id<OCTSubmanagerCallDelegate> delegate;

/**
 * All call sessions.
 */
@property (strong, nonatomic, readonly) OCTCallsContainer *calls;

/**
 * This class is responsible for telling the end-user what calls we have available.
 * We can also initialize a call session from here.
 * @param chat The chat for which we would like to initiate a call.
 * @param enableAudio YES for Audio, otherwise NO.
 * @param enableVideo YES for Video, otherwise NO.
 * @param error Pointer to an error when attempting to answer a call
 * @return OCTCall session
 */
- (OCTCall *)callToChat:(OCTChat *)chat enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError **)error;

/**
 * Answer a call
 * @param call The call session we would like to answer
 * @param enableAudio YES for Audio, otherwise NO.
 * @param enableVideo YES for Video, otherwise NO.
 * @param error Pointer to an error when attempting to answer a call
 * @return YES if we were able to succesfully answer the call, otherwise NO.
 **/
- (BOOL)answerCall:(OCTCall *)call enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError **)error;

/**
 * Pause the call
 * @param pause YES to pause, NO otherwise.
 * @call The appropriate OCTCall to pause
 * @return YES if successful, NO otherwise.
 **/
- (BOOL)togglePause:(BOOL)pause forCall:(OCTCall *)call error:(NSError **)error;

/**
 * End the call. Call can be ringing or in session.
 * @call The call to end.
 * @param error Pointer to error object if there's an issue with ending the call.
 * @return YES if successful, no otherwise.
 **/
- (BOOL)endCall:(OCTCall *)call error:(NSError **)error;

/**
 * Mutes the call
 * @param mute YES to mute, NO otherwise.
 * @param call Call to mute.
 * @param error Pointer to error object if there's an issue muting the call.
 * @return YES if successful, NO otherwise.
 **/
- (BOOL)toggleMute:(BOOL)mute forCall:(OCTCall *)call error:(NSError **)error;

/**
 * Toggle turning off or on the video feed
 * @param pause YES to stop the video, NO otherwise to continue.
 * @call Call to pause video.
 * @param error Pointer to error object if there's an issue pausing the video.
 * @return YES if successful, NO otherwise.
 **/
- (BOOL)togglePauseVideo:(BOOL)pause forCall:(OCTCall *)call error:(NSError **)error;

/**
 * The UIView that will have the video feed.
 * @param call The call that has the video feed.
 * @return UIView of the video feed. Nil if no video available.
 **/
- (UIView *)videoFeedForCall:(OCTCall *)call;

/**
 * Set the Audio bit rate.
 * @param bitrate The bitrate to change to.
 * @param call The Call to set the bitrate for.
 * @param error Pointer to error object if there's an issue setting the bitrate.
 */
- (BOOL)setAudioBitrate:(int)bitrate forCall:(OCTCall *)call error:(NSError **)error;

/**
 * Set the Video bit rate.
 * @param bitrate The bitrate to change to.
 * @param call The call to set the bitrate for.
 * @param error Pointer to error object if there's an issue setting the bitrate.
 */
- (BOOL)setVideoBitrate:(int)bitrate forCall:(OCTCall *)call error:(NSError **)error;
@end
