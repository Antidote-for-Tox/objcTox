//
//  OCTToxAV.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTToxAV.h"
#import "OCTTox+Private.h"
#import "toxav.h"
#import "DDLog.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

toxav_call_cb callIncomingCallback;
toxav_call_state_cb callStateCallback;
toxav_audio_bit_rate_status_cb audioBitRateStatusCallback;
toxav_video_bit_rate_status_cb videoBitRateStatusCallback;
toxav_audio_receive_frame_cb receiveAudioFrameCallback;
toxav_video_receive_frame_cb receiveVideoFrameCallback;

@interface OCTToxAV ()

@property (assign, nonatomic) ToxAV *toxAV;

@property (strong, nonatomic) dispatch_source_t timer;

@end

@implementation OCTToxAV

#pragma mark - Class Methods

+ (NSString *)version
{
    return [NSString stringWithFormat:@"%lu.%lu.%lu",
            (unsigned long)[self versionMajor], (unsigned long)[self versionMinor], (unsigned long)[self versionPatch]];
}

+ (NSUInteger)versionMajor
{
    return toxav_version_major();
}

+ (NSUInteger)versionMinor
{
    return toxav_version_minor();
}

+ (NSUInteger)versionPatch
{
    return toxav_version_patch();
}

+ (BOOL)versionIsCompatibleWith:(NSUInteger)major minor:(NSUInteger)minor patch:(NSUInteger)patch
{
    return toxav_version_is_compatible((uint32_t)major, (uint32_t)minor, (uint32_t)patch);
}

#pragma mark -  Lifecycle
- (instancetype)initWithTox:(OCTTox *)tox error:(NSError **)error
{
    self = [super init];

    if (! self) {
        return nil;
    }

    DDLogVerbose(@"%@: init called", self);

    TOXAV_ERR_NEW cError;
    _toxAV = toxav_new(tox.tox, &cError);

    [self fillError:error withCErrorInit:cError];

    toxav_callback_call(_toxAV, callIncomingCallback, (__bridge void *)(self));
    toxav_callback_call_state(_toxAV, callStateCallback, (__bridge void *)(self));
    toxav_callback_audio_bit_rate_status(_toxAV, audioBitRateStatusCallback, (__bridge void *)(self));
    toxav_callback_video_bit_rate_status(_toxAV, videoBitRateStatusCallback, (__bridge void *)(self));
    toxav_callback_audio_receive_frame(_toxAV, receiveAudioFrameCallback, (__bridge void *)(self));
    toxav_callback_video_receive_frame(_toxAV, receiveVideoFrameCallback, (__bridge void *)(self));

    return self;
}

- (void)start
{
    DDLogVerbose(@"%@: start method called", self);

    @synchronized(self) {
        if (self.timer) {
            DDLogWarn(@"%@: already started", self);
            return;
        }

        dispatch_queue_t queue = dispatch_queue_create("me.dvor.objcTox.OCTToxAVQueue", NULL);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

        uint64_t interval = toxav_iteration_interval(self.toxAV) * (NSEC_PER_SEC / 1000);
        dispatch_source_set_timer(self.timer, dispatch_walltime(NULL, 0), interval, interval / 5);

        __weak OCTToxAV *weakSelf = self;
        dispatch_source_set_event_handler(self.timer, ^{
            OCTToxAV *strongSelf = weakSelf;
            if (! strongSelf) {
                return;
            }

            toxav_iterate(strongSelf.toxAV);
        });

        dispatch_resume(self.timer);
    }
    DDLogInfo(@"%@: started", self);
}

- (void)stop
{
    DDLogVerbose(@"%@: stop method called", self);

    @synchronized(self) {
        if (! self.timer) {
            DDLogWarn(@"%@: toxav isn't running, nothing to stop", self);
            return;
        }

        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }

    DDLogInfo(@"%@: stopped", self);
}

- (void)dealloc
{
    [self stop];
    toxav_kill(self.toxAV);
    DDLogVerbose(@"%@: dealloc called, toxav killed", self);
}

#pragma mark - Call Methods

- (BOOL)callFriendNumber:(OCTToxFriendNumber)friendNumber audioBitRate:(OCTToxAVAudioBitRate)audioBitRate videoBitRate:(OCTToxAVVideoBitRate)videoBitRate error:(NSError **)error
{
    TOXAV_ERR_CALL cError;
    BOOL status = toxav_call(self.toxAV, friendNumber, audioBitRate, videoBitRate, &cError);

    [self fillError:error withCErrorCall:cError];

    return status;
}

- (BOOL)sendCallControl:(OCTToxAVCallControl)control toFriendNumber:(OCTToxFriendNumber)friendNumber error:(NSError **)error
{
    TOXAV_CALL_CONTROL cControl;

    switch (control) {
        case OCTToxAVCallControlResume:
            cControl = TOXAV_CALL_CONTROL_RESUME;
            break;
        case OCTToxAVCallControlPause:
            cControl = TOXAV_CALL_CONTROL_PAUSE;
            break;
        case OCTToxAVCallControlCancel:
            cControl = TOXAV_CALL_CONTROL_CANCEL;
            break;
        case OCTToxAVCallControlMuteAudio:
            cControl = TOXAV_CALL_CONTROL_MUTE_AUDIO;
            break;
        case OCTToxAVCallControlUnmuteAudio:
            cControl = TOXAV_CALL_CONTROL_UNMUTE_AUDIO;
            break;
        case OCTToxAVCallControlHideVideo:
            cControl = TOXAV_CALL_CONTROL_HIDE_VIDEO;
            break;
        case OCTToxAVCallControlShowVideo:
            cControl = TOXAV_CALL_CONTROL_SHOW_VIDEO;
            break;
    }

    TOXAV_ERR_CALL_CONTROL cError;

    BOOL status = toxav_call_control(self.toxAV, friendNumber, cControl, &cError);

    [self fillError:error withCErrorControl:cError];

    return status;
}

#pragma mark - Controlling bit rates

- (BOOL)setAudioBitRate:(OCTToxAVAudioBitRate)bitRate force:(BOOL)force forFriend:(OCTToxFriendNumber)friendNumber error:(NSError **)error
{
    TOXAV_ERR_SET_BIT_RATE cError;

    BOOL status = toxav_audio_bit_rate_set(self.toxAV, friendNumber, bitRate, force, &cError);

    [self fillError:error withCErrorSetBitRate:cError];

    return status;
}

- (BOOL)setVideoBitRate:(OCTToxAVVideoBitRate)bitRate force:(BOOL)force forFriend:(OCTToxFriendNumber)friendNumber error:(NSError **)error
{
    TOXAV_ERR_SET_BIT_RATE cError;

    BOOL status = toxav_video_bit_rate_set(self.toxAV, friendNumber, bitRate, force, &cError);

    [self fillError:error withCErrorSetBitRate:cError];

    return status;
}

#pragma mark - Sending frames
- (BOOL)sendAudioFrame:(OCTToxAVPCMData *)pcm sampleCount:(OCTToxAVSampleCount)sampleCount
              channels:(OCTToxAVChannels)channels sampleRate:(OCTToxAVSampleRate)sampleRate
              toFriend:(OCTToxFriendNumber)friendNumber error:(NSError **)error
{
    TOXAV_ERR_SEND_FRAME cError;

    BOOL status = toxav_audio_send_frame(self.toxAV, friendNumber,
                                         pcm, sampleCount,
                                         channels, sampleRate, &cError);

    [self fillError:error withCErrorSendFrame:cError];

    return status;
}

#pragma mark - Private

- (void)fillError:(NSError **)error withCErrorInit:(TOXAV_ERR_NEW)cError
{
    if (! error || (cError == TOXAV_ERR_NEW_OK)) {
        return;
    }

    OCTToxAVErrorInitCode code = OCTToxAVErrorInitCodeUnknown;
    NSString *description = @"Cannot initialize ToxAV";
    NSString *failureReason = nil;

    switch (cError) {
        case TOXAV_ERR_NEW_OK:
            NSAssert(NO, @"We shouldn't be here!");
            break;
        case TOXAV_ERR_NEW_NULL:
            code = OCTToxAVErrorInitNULL;
            failureReason = @"One of the arguments to the function was NULL when it was not expected.";
            break;
        case TOXAV_ERR_NEW_MALLOC:
            code = OCTToxAVErrorInitCodeMemoryError;
            failureReason = @"Memory allocation failure while trying to allocate structures required for the A/V session.";
            break;
        case TOXAV_ERR_NEW_MULTIPLE:
            code = OCTToxAVErrorInitMultiple;
            failureReason = @"Attempted to create a second session for the same Tox instance.";
            break;
    }
    *error = [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (void)fillError:(NSError **)error withCErrorCall:(TOXAV_ERR_CALL)cError
{
    if (! error || (cError == TOXAV_ERR_CALL_OK)) {
        return;
    }

    OCTToxAVErrorCall code = OCTToxAVErrorCallUnknown;
    NSString *description = @"Could not make call";
    NSString *failureReason = nil;

    switch (cError) {
        case TOXAV_ERR_CALL_OK:
            NSAssert(NO, @"We shouldn't be here!");
            break;
        case TOXAV_ERR_CALL_MALLOC:
            code = OCTToxAVErrorCallMalloc;
            failureReason = @"A resource allocation error occured while trying to create the structures required for the call.";
            break;
        case TOXAV_ERR_CALL_FRIEND_NOT_FOUND:
            code = OCTToxAVErrorCallFriendNotFound;
            failureReason = @"The friend number did not designate a valid friend.";
            break;
        case TOXAV_ERR_CALL_FRIEND_NOT_CONNECTED:
            code = OCTToxAVErrorCallFriendNotConnected;
            failureReason = @"The friend was valid, but not currently connected";
            break;
        case TOXAV_ERR_CALL_FRIEND_ALREADY_IN_CALL:
            code = OCTToxAVErrorCallAlreadyInCall;
            failureReason = @"Attempted to call a friend while already in an audio or video call with them.";
            break;
        case TOXAV_ERR_CALL_INVALID_BIT_RATE:
            code = OCTToxAVErrorCallInvalidBitRate;
            failureReason = @"Audio or video bit rate is invalid";
            break;
    }

    *error = [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (void)fillError:(NSError **)error withCErrorControl:(TOXAV_ERR_CALL_CONTROL)cError
{
    if (! error || (cError == TOXAV_ERR_CALL_CONTROL_OK)) {
        return;
    }

    OCTToxErrorCallControl code = OCTToxAVErrorControlUnknown;
    NSString *description = @"Unable set control";
    NSString *failureReason = nil;

    switch (cError) {
        case TOXAV_ERR_CALL_CONTROL_OK:
            NSAssert(NO, @"We shouldn't be here!");
            break;
        case TOXAV_ERR_CALL_CONTROL_FRIEND_NOT_FOUND:
            code = OCTToxAVErrorControlFriendNotFound;
            failureReason = @"The friend_number passed did not designate a valid friend.";
            break;
        case TOXAV_ERR_CALL_CONTROL_FRIEND_NOT_IN_CALL:
            code = OCTToxAVErrorControlFriendNotInCall;
            failureReason = @"This client is currently not in a call with the friend. Before the call is answered, only CANCEL is a valid control.";
            break;
        case TOXAV_ERR_CALL_CONTROL_INVALID_TRANSITION:
            code = OCTToxAVErrorControlInvaldTransition;
            failureReason = @"Happens if user tried to pause an already paused call or if trying to resume a call that is not paused.";
            break;
    }

    *error = [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (void)fillError:(NSError **)error withCErrorSetBitRate:(TOXAV_ERR_SET_BIT_RATE)cError
{
    if (! error || (cError == TOXAV_ERR_SET_BIT_RATE_OK)) {
        return;
    }

    OCTToxAVErrorSetBitRate code = OCTToxAVErrorSetBitRateUnknown;
    NSString *description = @"Unable to set audio/video bitrate";
    NSString *failureReason = nil;

    switch (cError) {
        case TOXAV_ERR_SET_BIT_RATE_OK:
            NSAssert(NO, @"We shouldn't be here!");
            break;
        case TOXAV_ERR_SET_BIT_RATE_INVALID:
            code = OCTToxAVErrorSetBitRateInvalid;
            failureReason = @"The bit rate passed was not one of the supported values.";
            break;
        case TOXAV_ERR_SET_BIT_RATE_FRIEND_NOT_FOUND:
            code = OCTToxAVErrorSetBitRateFriendNotFound;
            failureReason = @"The friend number passed did not designate a valid friend";
            break;
        case TOXAV_ERR_SET_BIT_RATE_FRIEND_NOT_IN_CALL:
            code = OCTToxAVErrorSetBitRateFriendNotInCall;
            failureReason = @"This client is currently not in a call with the friend";
            break;
    }

    *error = [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (void)fillError:(NSError **)error withCErrorSendFrame:(TOXAV_ERR_SEND_FRAME)cError
{
    if (! error || (cError == TOXAV_ERR_SEND_FRAME_OK)) {
        return;
    }

    OCTToxAVErrorSendFrame code = OCTToxAVErrorSendFrameUnknown;
    NSString *description = @"Failed to send audio/video frame";
    NSString *failureReason = @"Unable to sending audio/video frame";
    switch (cError) {
        case TOXAV_ERR_SEND_FRAME_OK:
            NSAssert(NO, @"We shouldn't be here!");
            break;
        case TOXAV_ERR_SEND_FRAME_NULL:
            code = OCTToxAVErrorSendFrameNull;
            failureReason = @"In case of video, one of Y, U, or V was NULL. In case of audio, the samples data pointer was NULL.";
            break;
        case TOXAV_ERR_SEND_FRAME_FRIEND_NOT_FOUND:
            code = OCTToxAVErrorSendFrameFriendNotFound;
            failureReason = @"The friend_number passed did not designate a valid friend.";
            break;
        case TOXAV_ERR_SEND_FRAME_FRIEND_NOT_IN_CALL:
            code = OCTToxAVErrorSendFrameFriendNotInCall;
            failureReason = @"This client is currently not in a call with the friend";
            break;
        case TOXAV_ERR_SEND_FRAME_INVALID:
            code = OCTToxAVErrorSendFrameInvalid;
            failureReason = @"One of the frame parameters was invalid. E.g. the resolution may be too small or too large, or the audio sampling rate may be unsupported";
            break;
        case TOXAV_ERR_SEND_FRAME_RTP_FAILED:
            code = OCTToxAVErrorSendFrameRTPFailed;
            failureReason = @"Failed to push frame through rtp interface";
            break;
    }

    *error = [self createErrorWithCode:code description:description failureReason:failureReason];
}

- (NSError *)createErrorWithCode:(NSUInteger)code
                     description:(NSString *)description
                   failureReason:(NSString *)failureReason
{
    NSMutableDictionary *userInfo = [NSMutableDictionary new];

    if (description) {
        userInfo[NSLocalizedDescriptionKey] = description;
    }

    if (failureReason) {
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason;
    }

    return [NSError errorWithDomain:kOCTToxAVErrorDomain code:code userInfo:userInfo];
}

@end

#pragma Callbacks

void callIncomingCallback(ToxAV *cToxAV,
                          OCTToxFriendNumber friendNumber,
                          bool audioEnabled,
                          bool videoEnabled,
                          void *userData)
{
    OCTToxAV *toxAV = (__bridge OCTToxAV *)userData;

    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogCInfo(@"%@: callIncomingCallback from friend %lu with audio:%d with video:%d", cToxAV, (unsigned long)friendNumber, audioEnabled, videoEnabled);
        if ([toxAV.delegate respondsToSelector:@selector(toxAV:receiveCallAudioEnabled:videoEnabled:friendNumber:)]) {
            [toxAV.delegate toxAV:toxAV receiveCallAudioEnabled:audioEnabled videoEnabled:videoEnabled friendNumber:friendNumber];
        }
    });
}

void callStateCallback(ToxAV *cToxAV,
                       OCTToxFriendNumber friendNumber,
                       enum TOXAV_CALL_STATE cState,
                       void *userData)
{
    OCTToxAV *toxAV = (__bridge OCTToxAV *)userData;

    dispatch_async(dispatch_get_main_queue(), ^{

        DDLogCInfo(@"%@: callStateCallback from friend %d with state: %d", cToxAV, friendNumber, cState);

        OCTToxAVCallState state = 0;

        if (cState & TOXAV_CALL_STATE_ERROR) {
            state |= OCTToxAVCallStateError;
        }
        if (cState & TOXAV_CALL_STATE_FINISHED) {
            state |= OCTToxAVCallStateFinished;
        }
        if (cState & TOXAV_CALL_STATE_SENDING_A) {
            state |= OCTToxAVCallStateSendingAudio;
        }
        if (cState & TOXAV_CALL_STATE_SENDING_V) {
            state |= OCTToxAVCallStateSendingVideo;
        }
        if (cState & TOXAV_CALL_STATE_RECEIVING_A) {
            state |= OCTToxAVCallStateReceivingAudio;
        }
        if (cState & TOXAV_CALL_STATE_RECEIVING_V) {
            state |= OCTToxAVCallStateReceivingVideo;
        }

        if ([toxAV.delegate respondsToSelector:@selector(toxAV:callStateChanged:friendNumber:)]) {
            [toxAV.delegate toxAV:toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:friendNumber];
        }
    });
}

void audioBitRateStatusCallback(ToxAV *cToxAV,
                                OCTToxFriendNumber friendNumber,
                                bool stable,
                                OCTToxAVAudioBitRate bitRate,
                                void *userData)
{
    OCTToxAV *toxAV = (__bridge OCTToxAV *)userData;

    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogCInfo(@"%@: audioBitRateStatusCallback from friend %d stable: %d bitRate: %d", cToxAV, friendNumber, stable, bitRate);
        if ([toxAV.delegate respondsToSelector:@selector(toxAV:audioBitRateChanged:stable:friendNumber:)]) {
            [toxAV.delegate toxAV:toxAV audioBitRateChanged:bitRate stable:stable friendNumber:friendNumber];
        }
    });
}

void videoBitRateStatusCallback(ToxAV *cToxAV,
                                OCTToxFriendNumber friendNumber,
                                bool stable,
                                OCTToxAVVideoBitRate bitRate,
                                void *userData)
{
    OCTToxAV *toxAV = (__bridge OCTToxAV *)userData;

    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogCInfo(@"%@: videoBitRateStatusCallback from friend %d stable: %d bitRate: %d", cToxAV, friendNumber, stable, bitRate);
        if ([toxAV.delegate respondsToSelector:@selector(toxAV:videoBitRateChanged:friendNumber:stable:)]) {
            [toxAV.delegate toxAV:toxAV videoBitRateChanged:bitRate friendNumber:friendNumber stable:stable];
        }
    });
}

void receiveAudioFrameCallback(ToxAV *cToxAV,
                               OCTToxFriendNumber friendNumber,
                               OCTToxAVPCMData *pcm,
                               OCTToxAVSampleCount sampleCount,
                               OCTToxAVChannels channels,
                               OCTToxAVSampleRate sampleRate,
                               void *userData)
{
    OCTToxAV *toxAV = (__bridge OCTToxAV *)userData;

    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogCInfo(@"%@: receiveAudioFrameCallback from friend %d sampleCount: %lu channels: %d", cToxAV, friendNumber, sampleCount, channels);
        if ([toxAV.delegate respondsToSelector:@selector(toxAV:receiveAudio:sampleCount:channels:sampleRate:friendNumber:)]) {
            [toxAV.delegate toxAV:toxAV receiveAudio:pcm sampleCount:sampleCount channels:channels sampleRate:sampleRate friendNumber:friendNumber];
        }
    });
}

void receiveVideoFrameCallback(ToxAV *cToxAV,
                               OCTToxFriendNumber friendNumber,
                               OCTToxAVVideoWidth width,
                               OCTToxAVVideoHeight height,
                               OCTToxAVPlaneData *yPlane, OCTToxAVPlaneData *uPlane, OCTToxAVPlaneData *vPlane, OCTToxAVPlaneData *aPlane,
                               OCTToxAVStrideData yStride, OCTToxAVStrideData uStride, OCTToxAVStrideData vStride, OCTToxAVStrideData aStride,
                               void *userData)
{
    OCTToxAV *toxAV = (__bridge OCTToxAV *)userData;

    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogCInfo(@"%@: receiveVideoFrameCallback from friend %d width: %d height: %d", cToxAV, friendNumber, width, height);
        if ([toxAV.delegate respondsToSelector:@selector(toxAV:receiveVideoFrameWithWidth:height:yPlane:uPlane:vPlane:aPlane:yStride:uStride:vStride:aStride:friendNumber:)]) {
            [toxAV.delegate toxAV:toxAV
             receiveVideoFrameWithWidth:width height:height
                                 yPlane:yPlane uPlane:uPlane vPlane:vPlane aPlane:aPlane
                                yStride:yStride uStride:uStride vStride:vStride aStride:aStride
                           friendNumber:friendNumber];
        }
    });
}
