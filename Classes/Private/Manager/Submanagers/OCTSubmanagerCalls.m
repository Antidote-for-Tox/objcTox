//
//  OCTCallSubmanager.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerCalls+Private.h"

const OCTToxAVAudioBitRate kDefaultAudioBitRate = OCTToxAVAudioBitRate48;
const OCTToxAVAudioBitRate kDefaultVideoBitRate = 400;

@interface OCTSubmanagerCalls () <OCTToxAVDelegate>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;
@property (strong, nonatomic) OCTCallTimer *timer;
@property (nonatomic, assign) dispatch_once_t setupOnceToken;

@end

@implementation OCTSubmanagerCalls : NSObject

- (instancetype)initWithTox:(OCTTox *)tox
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _toxAV = [[OCTToxAV alloc] initWithTox:tox error:nil];
    _toxAV.delegate = self;
    [_toxAV start];

    return self;
}

- (BOOL)setupWithError:(NSError **)error
{
    NSAssert(self.dataSource, @"dataSource is needed before setup of OCTSubmanagerCalls");
    __block BOOL status = NO;
    dispatch_once(&_setupOnceToken, ^{
        OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];
        self.timer = [[OCTCallTimer alloc] initWithRealmManager:realmManager];

        self.audioEngine = [OCTAudioEngine new];
        self.audioEngine.toxav = self.toxAV;
        status = [self.audioEngine setupWithError:error];
    });

    return status;
}

- (OCTCall *)callToChat:(OCTChat *)chat enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError **)error
{
    OCTToxAVAudioBitRate audioBitRate = (enableAudio) ? kDefaultAudioBitRate : OCTToxAVAudioBitRateDisabled;
    OCTToxAVVideoBitRate videoBitRate = (enableVideo) ? kDefaultVideoBitRate : kOCTToxAVVideoBitRateDisable;

    if (chat.friends.count == 1) {
        OCTFriend *friend = chat.friends.lastObject;
        self.audioEngine.friendNumber = friend.friendNumber;

        if (! [self.toxAV callFriendNumber:friend.friendNumber
                              audioBitRate:audioBitRate
                              videoBitRate:videoBitRate
                                     error:error]) {
            return nil;
        }

        OCTCall *call = [self getOrCreateCallWithFriendNumber:friend.friendNumber];
        [self updateCall:call withStatus:OCTCallStatusDialing];

        return call;
    }
    else {
        // TO DO: Group Calls
        return nil;
    }
    return nil;
}

- (BOOL)answerCall:(OCTCall *)call enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError **)error
{
    OCTToxAVAudioBitRate audioBitRate = (enableAudio) ? kDefaultAudioBitRate : OCTToxAVAudioBitRateDisabled;
    OCTToxAVVideoBitRate videoBitRate = (enableVideo) ? kDefaultVideoBitRate : kOCTToxAVVideoBitRateDisable;

    if (call.chat.friends.count == 1) {

        OCTFriend *friend = call.chat.friends.firstObject;

        if (! ([self.toxAV answerIncomingCallFromFriend:friend.friendNumber
                                           audioBitRate:audioBitRate
                                           videoBitRate:videoBitRate
                                                  error:error] &&
               [self.audioEngine startAudioFlow:error])) {
            return NO;
        }

        self.audioEngine.friendNumber = friend.friendNumber;
        [self updateCall:call withStatus:OCTCallStatusActive];
        [self.timer startTimerForCall:call];

        return YES;
    }
    else {
        // TO DO: Group Calls
        return NO;
    }
}

- (BOOL)routeAudioToSpeaker:(BOOL)speaker error:(NSError **)error
{
    return [self.audioEngine routeAudioToSpeaker:speaker error:error];
}

- (BOOL)enableMicrophone
{
    return self.audioEngine.enableMicrophone;
}

- (void)setEnableMicrophone:(BOOL)enableMicrophone
{
    self.audioEngine.enableMicrophone = enableMicrophone;
}

- (BOOL)sendCallControl:(OCTToxAVCallControl)control toCall:(OCTCall *)call error:(NSError **)error
{
    if (call.chat.friends.count == 1) {

        OCTFriend *friend = call.chat.friends.firstObject;

        if (! [self.toxAV sendCallControl:control toFriendNumber:friend.friendNumber error:error]) {
            return NO;
        }

        switch (control) {
            case OCTToxAVCallControlResume:
                [self updateCall:call withStatus:OCTCallStatusActive];
                break;
            case OCTToxAVCallControlCancel:
                [self.timer stopTimer];
                [self addMessageCall:call];
                return [self.audioEngine stopAudioFlow:error];
            case OCTToxAVCallControlPause:
                break;
            case OCTToxAVCallControlUnmuteAudio:
                break;
            case OCTToxAVCallControlMuteAudio:
                break;
            case OCTToxAVCallControlHideVideo:
                break;
            case OCTToxAVCallControlShowVideo:
                break;
        }
        return YES;
    }
    else {
        return NO;
    }
}

- (UIView *)videoFeedForCall:(OCTCall *)call
{
    return nil;
}

- (BOOL)setAudioBitrate:(int)bitrate forCall:(OCTCall *)call error:(NSError **)error
{
    if (call.chat.friends.count == 1) {

        OCTFriend *friend = call.chat.friends.firstObject;

        return [self.toxAV setAudioBitRate:bitrate force:NO forFriend:friend.friendNumber error:error];
    }
    else {
        // TO DO: Group Calls
        return NO;
    }
}

- (BOOL)setVideoBitrate:(int)bitrate forCall:(OCTCall *)call error:(NSError **)error
{
    if (call.chat.friends.count == 1) {

        OCTFriend *friend = call.chat.friends.firstObject;

        return [self.toxAV setVideoBitRate:bitrate force:NO forFriend:friend.friendNumber error:error];
    }
    else {
        // TO DO: Group Calls
        return NO;
    }
}

#pragma mark Private methods
- (OCTCall *)getOrCreateCallWithFriendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    OCTFriend *friend = [realmManager friendWithFriendNumber:friendNumber];
    OCTChat *chat = [realmManager getOrCreateChatWithFriend:friend];

    return [realmManager getOrCreateCallWithChat:chat];
}

- (void)updateCall:(OCTCall *)call withStatus:(OCTCallStatus)status
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];
    [realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        callToUpdate.status = status;
    }];
}

- (void)addMessageCall:(OCTCall *)call
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];
    [realmManager addMessageCall:call];

    [self.timer stopTimer];
    [realmManager deleteObject:call];
}

- (void)updateCall:(OCTCall *)call withState:(OCTToxAVCallState)state
{
    BOOL sendingAudio, sendingVideo, receivingAudio, receivingVideo;

    if (state & OCTToxAVFriendCallStateReceivingAudio) {
        receivingAudio = YES;
    }

    if (state & OCTToxAVFriendCallStateReceivingVideo) {
        receivingVideo = YES;
    }

    if (state & OCTToxAVFriendCallStateSendingAudio) {
        sendingAudio = YES;
    }

    if (state & OCTToxAVFriendCallStateSendingVideo) {
        sendingVideo = YES;
    }

    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];
    [realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        callToUpdate.receivingAudio = receivingAudio;
        callToUpdate.receivingVideo = receivingVideo;
        callToUpdate.sendingAudio = sendingAudio;
        callToUpdate.sendingVideo = sendingVideo;
    }];
}

#pragma mark OCTToxAV delegate methods

- (void)toxAV:(OCTToxAV *)toxAV receiveCallAudioEnabled:(BOOL)audio videoEnabled:(BOOL)video friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTCall *call = [self getOrCreateCallWithFriendNumber:friendNumber];
    [self updateCall:call withStatus:OCTCallStatusRinging];

    if ([self.delegate respondsToSelector:@selector(callSubmanager:receiveCall:audioEnabled:videoEnabled:)]) {
        [self.delegate callSubmanager:self receiveCall:call audioEnabled:audio videoEnabled:video];
    }
}

- (void)toxAV:(OCTToxAV *)toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTCall *call = [self getOrCreateCallWithFriendNumber:friendNumber];

    if ((state & OCTToxAVFriendCallStateFinished) || (state & OCTToxAVFriendCallStateError)) {

        [self addMessageCall:call];

        [self.audioEngine stopAudioFlow:nil];

        return;
    }

    if (call.status == OCTCallStatusDialing) {
        [self updateCall:call withStatus:OCTCallStatusActive];
        self.audioEngine.friendNumber = friendNumber;
        [self.audioEngine startAudioFlow:nil];
        [self.timer startTimerForCall:call];
    }

    [self updateCall:call withState:state];
}

- (void)toxAV:(OCTToxAV *)toxAV audioBitRateChanged:(OCTToxAVAudioBitRate)bitrate stable:(BOOL)stable friendNumber:(OCTToxFriendNumber)friendNumber
{
    if (stable) {
        return;
    }

    OCTToxAVAudioBitRate newBitrate;

    switch (bitrate) {
        case OCTToxAVAudioBitRate48:
            newBitrate = OCTToxAVAudioBitRate32;
            break;
        case OCTToxAVAudioBitRate32:
            newBitrate = OCTToxAVAudioBitRate24;
            break;
        case OCTToxAVAudioBitRate24:
            newBitrate = OCTToxAVAudioBitRate16;
            break;
        case OCTToxAVAudioBitRate16:
            newBitrate = OCTToxAVAudioBitRate8;
            break;
        case OCTToxAVAudioBitRate8:
            return;
        case OCTToxAVAudioBitRateDisabled:
            NSAssert(NO, @"We shouldn't be here!");
            break;
    }

    [self.toxAV setAudioBitRate:newBitrate force:NO forFriend:friendNumber error:nil];
}

- (void)toxAV:(OCTToxAV *)toxAV videoBitRateChanged:(OCTToxAVVideoBitRate)bitrate friendNumber:(OCTToxFriendNumber)friendNumber stable:(BOOL)stable
{}

- (void)   toxAV:(OCTToxAV *)toxAV
    receiveAudio:(OCTToxAVPCMData *)pcm
     sampleCount:(OCTToxAVSampleCount)sampleCount
        channels:(OCTToxAVChannels)channels
      sampleRate:(OCTToxAVSampleRate)sampleRate
    friendNumber:(OCTToxFriendNumber)friendNumber
{
    [self.audioEngine provideAudioFrames:pcm sampleCount:sampleCount channels:channels sampleRate:sampleRate];
}

- (void)                 toxAV:(OCTToxAV *)toxAV
    receiveVideoFrameWithWidth:(OCTToxAVVideoWidth)width height:(OCTToxAVVideoHeight)height
                        yPlane:(OCTToxAVPlaneData *)yPlane uPlane:(OCTToxAVPlaneData *)uPlane
                        vPlane:(OCTToxAVPlaneData *)vPlane aPlane:(OCTToxAVPlaneData *)aPlane
                       yStride:(OCTToxAVStrideData)yStride uStride:(OCTToxAVStrideData)uStride
                       vStride:(OCTToxAVStrideData)vStride aStride:(OCTToxAVStrideData)aStride
                  friendNumber:(OCTToxFriendNumber)friendNumber
{}

@end
