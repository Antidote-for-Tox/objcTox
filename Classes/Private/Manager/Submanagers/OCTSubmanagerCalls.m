//
//  OCTCallSubmanager.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerCalls+Private.h"

@interface OCTSubmanagerCalls () <OCTToxAVDelegate>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;
@property (strong, nonatomic) OCTConverterChat *chatConverter;
@property (strong, nonatomic) NSMutableSet *mutableCalls;

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

    _audioEngine = [OCTAudioEngine new];
    _audioEngine.toxav = self.toxAV;

    _chatConverter = [OCTConverterChat new];

    _mutableCalls = [NSMutableSet new];

    return self;
}

- (NSSet *)calls
{
    return [self.mutableCalls copy];
}

- (OCTCall *)callToChat:(OCTChat *)chat enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo
{
    OCTToxAVAudioBitRate audioBitRate = (enableAudio) ? 24000 : kOCTToxAVAudioBitRateDisable;
    OCTToxAVVideoBitRate videoBitRate = (enableVideo) ? 400 : kOCTToxAVVideoBitRateDisable;

    OCTFriend *friend = chat.friends.lastObject;
    self.audioEngine.friendNumber = friend.friendNumber;

    [self.toxAV callFriendNumber:(OCTToxFriendNumber)friend
                    audioBitRate:audioBitRate
                    videoBitRate:videoBitRate
                           error:nil];

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    call.status = OCTCallStatusDialing;

    [self.mutableCalls addObject:call];

    return call;
}

- (BOOL)answerCall:(OCTCall *)call enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError **)error
{
    return NO;
}

- (BOOL)togglePause:(BOOL)pause forCall:(OCTCall *)call error:(NSError **)error
{
    OCTToxAVCallControl control = (pause) ? OCTToxAVCallControlPause : OCTToxAVCallControlResume;
    call.status = (pause) ? OCTCallStatusPaused : OCTCallStatusActive;

    OCTFriend *friend = call.chat.friends.firstObject;
    return [self.toxAV sendCallControl:control toFriendNumber:friend.friendNumber error:error];
}

- (BOOL)endCall:(OCTCall *)call error:(NSError **)error
{
    OCTFriend *friend = call.chat.friends.firstObject;
    [self.mutableCalls removeObject:call];

    return [self.toxAV sendCallControl:OCTToxAVCallControlCancel toFriendNumber:friend.friendNumber error:error];
}

- (BOOL)toggleMute:(BOOL)mute forCall:(OCTCall *)call error:(NSError **)error
{
    return NO;
}

- (BOOL)togglePauseVideo:(BOOL)pause forCall:(OCTCall *)call error:(NSError **)error
{
    return NO;
}

- (UIView *)videoFeedForCall:(OCTCall *)call
{
    return nil;
}

- (void)setAudioBitrate:(int)bitrate forCall:(OCTCall *)call error:(NSError **)error
{
    // To Do
}

- (void)setVideoBitrate:(int)bitrate forCall:(OCTCall *)call error:(NSError **)error
{
    // To Do
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

    [self.mutableCalls addObject:call];

    [self.delegate callSubmanager:self receiveCall:call audioEnabled:audio videoEnabled:video];
}

- (void)toxAV:(OCTToxAV *)toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:(OCTToxFriendNumber)friendNumber
{}

- (void)toxAV:(OCTToxAV *)toxAV audioBitRateChanged:(OCTToxAVAudioBitRate)bitrate stable:(BOOL)stable friendNumber:(OCTToxFriendNumber)friendNumber
{}

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
