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
@property (strong, nonatomic) NSMutableArray *calls;

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

    _calls = [NSMutableArray new];

    return self;
}

- (NSArray *)allCalls
{
    return self.calls;
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

        OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
        call.status = OCTCallStatusDialing;

        [self.calls addObject:call];

        return call;
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

        if (! ([self.toxAV answerIncomingCallFromFriend:friend.friendNumber
                                           audioBitRate:audioBitRate
                                           videoBitRate:videoBitRate
                                                  error:error] &&
               [self.audioEngine startAudioFlow:error])) {
            return NO;
        }

        self.audioEngine.friendNumber = friend.friendNumber;
        call.status = OCTCallStatusInSession;
        [call startTimer];

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
                [call startTimer];
                break;
            case OCTToxAVCallControlCancel:
                [call stopTimer];
                //log message here.
                return [self.audioEngine stopAudioFlow:error];
            case OCTToxAVCallControlPause:
                [call stopTimer];
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
- (OCTCall *)getOrCreateCallFromFriend:(OCTToxFriendNumber)friendNumber
{
    NSUInteger index = [self.calls indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        OCTCall *otherCall = obj;
        OCTFriend *friend = otherCall.chat.friends.firstObject;

        if (friend.friendNumber == friendNumber) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    if (index != NSNotFound) {
        return [self.calls objectAtIndex:index];
    }

    OCTChat *chat = [self getOrCreateChatWithFriend:friendNumber];

    return [[OCTCall alloc] initCallWithChat:chat];
}

- (OCTChat *)getOrCreateChatWithFriend:(OCTToxFriendNumber)friendNumber
{
    OCTFriend *friend = [[self.dataSource managerGetRealmManager] friendWithFriendNumber:friendNumber];

    return [[self.dataSource managerGetRealmManager] getOrCreateChatWithFriend:friend];
}

- (void)logCall:(OCTCall *)call setTimerActive:(BOOL)active withType:(OCTMessageCallEvent)type
{
    //TO DO: FIX
}

#pragma mark OCTToxAV delegate methods

- (void)toxAV:(OCTToxAV *)toxAV receiveCallAudioEnabled:(BOOL)audio videoEnabled:(BOOL)video friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTCall *call = [self getOrCreateCallFromFriend:friendNumber];
    call.status = OCTCallStatusIncoming;

    [self.calls addObject:call];

    if ([self.delegate respondsToSelector:@selector(callSubmanager:receiveCall:audioEnabled:videoEnabled:)]) {
        [self.delegate callSubmanager:self receiveCall:call audioEnabled:audio videoEnabled:video];
    }
}

- (void)toxAV:(OCTToxAV *)toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTCall *call = [self getOrCreateCallFromFriend:friendNumber];

    if ((state & OCTToxAVCallStateFinished) || (state & OCTToxAVCallStateError)) {

        if (call.status == OCTCallStatusIncoming) {
            [self logCall:call setTimerActive:NO withType:OCTMessageCallEventMissed];
        }
        else {
            [self logCall:call setTimerActive:NO withType:OCTMessageCallEventEnd];
        }

        [self.audioEngine stopAudioFlow:nil];
    }
    else if (call.status == OCTCallStatusDialing) {

        call.status = OCTCallStatusInSession;
    }

    call.state = state;

    if ([self.delegate respondsToSelector:@selector(callSubmanager:stateChanged:forCall:)]) {
        [self.delegate callSubmanager:self stateChanged:state forCall:call];
    }
}

- (void)toxAV:(OCTToxAV *)toxAV audioBitRateChanged:(OCTToxAVAudioBitRate)bitrate stable:(BOOL)stable friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTCall *call = [self getOrCreateCallFromFriend:friendNumber];

    if ([self.delegate respondsToSelector:@selector(callSubmanager:audioBitRateChanged:stable:forCall:)]) {
        [self.delegate callSubmanager:self audioBitRateChanged:bitrate stable:stable forCall:call];
    }
}

- (void)toxAV:(OCTToxAV *)toxAV videoBitRateChanged:(OCTToxAVVideoBitRate)bitrate friendNumber:(OCTToxFriendNumber)friendNumber stable:(BOOL)stable
{
    OCTCall *call = [self getOrCreateCallFromFriend:friendNumber];

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
