//
//  OCTToxAV+Private.h
//  objcTox
//
//  Created by Chuong Vu on 6/5/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTToxAV.h"
#import "toxav.h"

/**
 * ToxAV functions
 */

/**
 * Callbacks
 */
toxav_call_cb callIncomingCallback;
toxav_call_state_cb callStateCallback;
toxav_audio_bit_rate_status_cb audioBitRateStatusCallback;
toxav_video_bit_rate_status_cb videoBitRateStatusCallback;
toxav_audio_receive_frame_cb receiveAudioFrameCallback;
toxav_video_receive_frame_cb receiveVideoFrameCallback;

@interface OCTToxAV (Private)

- (void)fillError:(NSError **)error withCErrorInit:(TOXAV_ERR_NEW)cError;
- (void)fillError:(NSError **)error withCErrorCall:(TOXAV_ERR_CALL)cError;
- (void)fillError:(NSError **)error withCErrorControl:(TOXAV_ERR_CALL_CONTROL)cError;
- (void)fillError:(NSError **)error withCErrorSetBitRate:(TOXAV_ERR_SET_BIT_RATE)cError;
- (void)fillError:(NSError **)error withCErrorSendFrame:(TOXAV_ERR_SEND_FRAME)cError;
- (NSError *)createErrorWithCode:(NSUInteger)code
                     description:(NSString *)description
                   failureReason:(NSString *)failureReason;

@end