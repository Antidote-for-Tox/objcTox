//
//  OCTCallSubmanager.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerCalls+Private.h"

const OCTToxAVAudioBitRate kDefaultAudioBitRate = 48;
const OCTToxAVAudioBitRate kDefaultVideoBitRate = 400;

@interface OCTSubmanagerCalls () <OCTToxAVDelegate>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;
@property (strong, nonatomic) OCTTimer *timer;

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

    _audioEngine = [OCTAudioEngine new];
    _audioEngine.toxav = self.toxAV;
    [_audioEngine setupWithError:nil];

    _timer = [OCTTimer new];
    _timer.dataSource = _dataSource;

    return self;
}

- (OCTCall *)callToChat:(OCTChat *)chat enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError **)error
{
    OCTToxAVAudioBitRate audioBitRate = (enableAudio) ? kDefaultAudioBitRate : kOCTToxAVAudioBitRateDisable;
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

        OCTCall *call = [self getOrCreateCallWithFriend:friend.friendNumber];
        [self updateCall:call withStatus:OCTCallStatusDialing];
        [self addMessageCall:OCTMessageCallEventDial forCall:call withDuration:0];

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
    OCTToxAVAudioBitRate audioBitRate = (enableAudio) ? kDefaultAudioBitRate : kOCTToxAVAudioBitRateDisable;
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
        [self updateCall:call withStatus:OCTCallStatusInSession];
        [self addMessageCall:OCTMessageCallEventStarted forCall:call withDuration:0];

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
                [self updateCall:call withStatus:OCTCallStatusInSession];
                break;
            case OCTToxAVCallControlCancel:
                [self addMessageCall:OCTMessageCallEventEnd forCall:call withDuration:call.callDuration];
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
- (OCTCall *)getOrCreateCallWithFriend:(OCTToxFriendNumber)friendNumber
{
    return [[self.dataSource managerGetRealmManager] getOrCreateCallWithFriendNumber:friendNumber];
}

- (void)updateCall:(OCTCall *)call withStatus:(OCTCallStatus)status
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];
    [realmManager updateObject:call withBlock:^(id theObject) {
        OCTCall *dbCall = theObject;
        dbCall.status = status;
    }];
}

- (void)updateCall:(OCTCall *)call withState:(OCTToxAVCallState)state
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];
    [realmManager updateObject:call withBlock:^(id theObject) {
        OCTCall *dbCall = theObject;
        dbCall.state = state;
    }];
}

- (void)addMessageCall:(OCTMessageCallEvent)event forCall:(OCTCall *)call withDuration:(NSTimeInterval)duration
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];
    [realmManager addMessageCall:event call:call callDuration:duration];

    if (event == OCTMessageCallEventEnd) {
        [realmManager deleteObject:call];
    }
}

#pragma mark OCTToxAV delegate methods

- (void)toxAV:(OCTToxAV *)toxAV receiveCallAudioEnabled:(BOOL)audio videoEnabled:(BOOL)video friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTCall *call = [self getOrCreateCallWithFriend:friendNumber];
    [self updateCall:call withStatus:OCTCallStatusIncoming];

    if ([self.delegate respondsToSelector:@selector(callSubmanager:receiveCall:audioEnabled:videoEnabled:)]) {
        [self.delegate callSubmanager:self receiveCall:call audioEnabled:audio videoEnabled:video];
    }
}

- (void)toxAV:(OCTToxAV *)toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTCall *call = [self getOrCreateCallWithFriend:friendNumber];

    if ((state & OCTToxAVCallStateFinished) || (state & OCTToxAVCallStateError)) {

        if (call.status == OCTCallStatusIncoming) {
            [self addMessageCall:OCTMessageCallEventDial forCall:call withDuration:0];
        }
        else {
            [self addMessageCall:OCTMessageCallEventEnd forCall:call withDuration:call.callDuration];
        }

        [self.audioEngine stopAudioFlow:nil];
    }
    else if (call.status == OCTCallStatusDialing) {
        [self updateCall:call withStatus:OCTCallStatusInSession];
    }
    [self updateCall:call withState:state];
}

- (void)toxAV:(OCTToxAV *)toxAV audioBitRateChanged:(OCTToxAVAudioBitRate)bitrate stable:(BOOL)stable friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTCall *call = [self getOrCreateCallWithFriend:friendNumber];

    if ([self.delegate respondsToSelector:@selector(callSubmanager:audioBitRateChanged:stable:forCall:)]) {
        [self.delegate callSubmanager:self audioBitRateChanged:bitrate stable:stable forCall:call];
    }
}

- (void)toxAV:(OCTToxAV *)toxAV videoBitRateChanged:(OCTToxAVVideoBitRate)bitrate friendNumber:(OCTToxFriendNumber)friendNumber stable:(BOOL)stable
{
    OCTCall *call = [self getOrCreateCallWithFriend:friendNumber];

    if ([self.delegate respondsToSelector:@selector(callSubmanager:audioBitRateChanged:stable:forCall:)]) {
        [self.delegate callSubmanager:self videoBitRateChanged:bitrate stable:stable forCall:call];
    }
}

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
