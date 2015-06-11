//
//  OCTCallSubmanager.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerCalls+Private.h"

const OCTToxAVAudioBitRate kDefaultAudioBitRate = 24000;
const OCTToxAVAudioBitRate kDefaultVideoBitRate = 400;

@interface OCTSubmanagerCalls () <OCTToxAVDelegate>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;
@property (strong, nonatomic) OCTConverterChat *chatConverter;
@property (strong, nonatomic, readwrite) OCTCallsContainer *calls;

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

    _chatConverter = [OCTConverterChat new];

    _calls = [OCTCallsContainer new];

    return self;
}

- (OCTCall *)callToChat:(OCTChat *)chat enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo
{
    OCTToxAVAudioBitRate audioBitRate = (enableAudio) ? kDefaultAudioBitRate : kOCTToxAVAudioBitRateDisable;
    OCTToxAVVideoBitRate videoBitRate = (enableVideo) ? kDefaultVideoBitRate : kOCTToxAVVideoBitRateDisable;

    if (chat.friends.count == 1) {
        OCTFriend *friend = chat.friends.lastObject;
        self.audioEngine.friendNumber = friend.friendNumber;

        if ([self.toxAV callFriendNumber:(OCTToxFriendNumber)friend
                            audioBitRate:audioBitRate
                            videoBitRate:videoBitRate
                                   error:nil]) {
            OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
            call.status = OCTCallStatusDialing;

            [self.calls addCall:call];
            return call;
        }
        return nil;
    }
    else {
        // TO DO: Group Calls
        return nil;
    }
}

- (BOOL)answerCall:(OCTCall *)call enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError **)error
{
    OCTToxAVAudioBitRate audioBitRate = (enableAudio) ? kDefaultAudioBitRate : kOCTToxAVAudioBitRateDisable;
    OCTToxAVVideoBitRate videoBitRate = (enableVideo) ? kDefaultVideoBitRate : kOCTToxAVVideoBitRateDisable;

    if (call.chat.friends.count == 1) {

        OCTFriend *friend = call.chat.friends.firstObject;

        BOOL status = [self.toxAV answerIncomingCallFromFriend:friend.friendNumber audioBitRate:audioBitRate videoBitRate:videoBitRate error:error];

        [self.calls updateCallWithChat:call.chat updateBlock:^(OCTCall *call) {
            call.status = (status) ? OCTCallStatusActive : OCTCallStatusInactive;
        }];

        if (status) {
            self.audioEngine.friendNumber = friend.friendNumber;
            [self.audioEngine startAudioFlow:error];
        }

        return status;
    }
    else {
        // TO DO: Group Calls
        return NO;
    }
}

- (BOOL)togglePause:(BOOL)pause forCall:(OCTCall *)call error:(NSError **)error
{
    OCTToxAVCallControl control = (pause) ? OCTToxAVCallControlPause : OCTToxAVCallControlResume;

    if (call.chat.friends.count == 1) {

        OCTFriend *friend = call.chat.friends.firstObject;

        BOOL status =  [self.toxAV sendCallControl:control toFriendNumber:friend.friendNumber error:error];

        if (status) {
            [self.calls updateCallWithChat:call.chat updateBlock:^(OCTCall *call) {
                if (control == OCTToxAVCallControlPause) {
                    call.status = OCTCallStatusPaused;
                }
                else {
                    call.status = OCTCallStatusActive;
                }
            }];
        }
        return status;
    }
    else {
        // TO DO: Group Calls
        return NO;
    }
}

- (BOOL)endCall:(OCTCall *)call error:(NSError **)error
{
    if (call.chat.friends.count == 1) {
        OCTFriend *friend = call.chat.friends.firstObject;
        [self.calls removeCall:call];
        // TO DO: Add OCTMessageCall to db

        return ([self.toxAV sendCallControl:OCTToxAVCallControlCancel toFriendNumber:friend.friendNumber error:error] &&
                [self.audioEngine stopAudioFlow:error]);
    }
    else {
        // TO DO: Group Calls
        return NO;
    }
}

- (BOOL)toggleMute:(BOOL)mute forCall:(OCTCall *)call error:(NSError **)error
{
    OCTToxAVCallControl control = (mute) ? OCTToxAVCallControlMuteAudio : OCTToxAVCallControlUnmuteAudio;

    if (call.chat.friends.count == 1) {
        OCTFriend *friend = call.chat.friends.firstObject;
        return [self.toxAV sendCallControl:control toFriendNumber:friend.friendNumber error:error];
    }
    else {
        // TO DO: Group Calls
        return NO;
    }
}

- (BOOL)togglePauseVideo:(BOOL)pause forCall:(OCTCall *)call error:(NSError **)error
{
    OCTToxAVCallControl control = (pause) ? OCTToxAVCallControlHideVideo : OCTToxAVCallControlShowVideo;

    if (call.chat.friends.count == 1) {
        OCTFriend *friend = call.chat.friends.firstObject;
        return [self.toxAV sendCallControl:control toFriendNumber:friend.friendNumber error:error];
    }
    else {
        // TO DO: Group Calls
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

#pragma mark OCTToxAV delegate methods

- (void)toxAV:(OCTToxAV *)toxAV receiveCallAudioEnabled:(BOOL)audio videoEnabled:(BOOL)video friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTDBManager *dbManager = [self.dataSource managerGetDBManager];
    OCTDBChat *chatDB = [dbManager getOrCreateChatWithFriendNumber:friendNumber];
    OCTChat *chat = [self.chatConverter objectFromRLMObject:chatDB];

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    call.status = OCTCallStatusIncoming;

    [self.calls addCall:call];

    if ([self.delegate respondsToSelector:@selector(callSubmanager:receiveCall:audioEnabled:videoEnabled:)]) {
        [self.delegate callSubmanager:self receiveCall:call audioEnabled:audio videoEnabled:video];
    }
}

- (void)toxAV:(OCTToxAV *)toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTDBManager *dbManager = [self.dataSource managerGetDBManager];
    OCTDBChat *dbChat = [dbManager getOrCreateChatWithFriendNumber:friendNumber];
    OCTChat *chat = [self.chatConverter objectFromRLMObject:dbChat];

    [self.calls updateCallWithChat:chat updateBlock:^(OCTCall *call) {
        call.state = state;
        if (((state & OCTToxAVCallStateError) != 0) || ((state & OCTToxAVCallStateFinished) != 0)) {
            call.status = OCTCallStatusInactive;
        }
    }];
}

- (void)toxAV:(OCTToxAV *)toxAV audioBitRateChanged:(OCTToxAVAudioBitRate)bitrate stable:(BOOL)stable friendNumber:(OCTToxFriendNumber)friendNumber
{
    if ([self.delegate respondsToSelector:@selector(callSubmanager:audioBitRateChanged:stable:forCall:)]) {
        OCTDBManager *dbManager = [self.dataSource managerGetDBManager];
        OCTDBChat *dbChat = [dbManager getOrCreateChatWithFriendNumber:friendNumber];
        OCTChat *chat = [self.chatConverter objectFromRLMObject:dbChat];

        OCTCall *call = [self.calls callWithFriend:chat.friends.firstObject];
        [self.delegate callSubmanager:self audioBitRateChanged:bitrate stable:stable forCall:call];
    }
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
