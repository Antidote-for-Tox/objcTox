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
 * Layer of the preview video.
 */
- (CALayer *)videoCallPreview;

@end
