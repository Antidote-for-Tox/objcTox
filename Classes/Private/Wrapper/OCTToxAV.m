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
toxav_call_state_cb callstateCallback;
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
    toxav_callback_call_state(_toxAV, callstateCallback, (__bridge void *)(self));
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
    NSParameterAssert(friendNumber);

    TOXAV_ERR_CALL cError;
    BOOL status = toxav_call(self.toxAV, friendNumber, audioBitRate, videoBitRate, &cError);

    [self fillError:error withCErrorCall:cError];

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
            return;
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
    // To Do..
}

void callstateCallback(ToxAV *cToxAV,
                       OCTToxFriendNumber friendNumber,
                       uint32_t state,
                       void *userData)
{
    // To Do..
}

void audioBitRateStatusCallback(ToxAV *cToxAV,
                                OCTToxFriendNumber friendNumber,
                                bool stable,
                                OCTToxAVAudioBitRate bitRate,
                                void *userData)
{
    // To Do..
}

void videoBitRateStatusCallback(ToxAV *cToxAV,
                                OCTToxFriendNumber friendNumber,
                                bool stable,
                                OCTToxAVVideoBitRate bitRate,
                                void *userData)
{
    // To Do..
}

void receiveAudioFrameCallback(ToxAV *cToxAv,
                               OCTToxFriendNumber friendNumber,
                               OCTToxAVPCMData *pcm,
                               OCTToxAVSampleCount sampleCount,
                               OCTToxAVChannels channels,
                               OCTToxAVSampleRate sampleRate,
                               void *userData)
{
    // To Do..
}

void receiveVideoFrameCallback(ToxAV *cToxAV,
                               OCTToxFriendNumber friendNumber,
                               OCTToxAVVideoWidth width,
                               OCTToxAVVideoHeight height,
                               OCTToxAVPlaneData *yPlane, OCTToxAVPlaneData *uPlane, OCTToxAVPlaneData *vPlane, OCTToxAVPlaneData *aPlane,
                               OCTToxAVStrideData yStride, OCTToxAVStrideData uStride, OCTToxAVStrideData vStride, OCTToxAVStrideData aStride,
                               void *userData)
{
    // To Do..
}
