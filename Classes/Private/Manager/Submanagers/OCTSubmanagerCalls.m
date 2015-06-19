//
//  OCTCallSubmanager.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerCalls+Private.h"
#import "OCTConverterFriend.h"
#import "OCTConverterMessage.h"

const OCTToxAVAudioBitRate kDefaultAudioBitRate = 48;
const OCTToxAVAudioBitRate kDefaultVideoBitRate = 400;

@interface OCTSubmanagerCalls () <OCTToxAVDelegate, OCTConverterChatDelegate, OCTConverterFriendDataSource>

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
    [_audioEngine setupWithError:nil];

    OCTConverterFriend *friendConverter = [OCTConverterFriend new];
    friendConverter.dataSource = self;

    OCTConverterMessage *messageConverter = [OCTConverterMessage new];
    messageConverter.converterFriend = friendConverter;

    _chatConverter = [OCTConverterChat new];
    _chatConverter.delegate = self;
    _chatConverter.converterFriend = friendConverter;
    _chatConverter.converterMessage = messageConverter;

    _calls = [OCTCallsContainer new];

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

        OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
        call.status = OCTCallStatusDialing;

        [self.calls addCall:call];
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
        [self.calls updateCall:call updateBlock:^(OCTCall *callToUpdate) {
            [self setCallActiveAndStartTimer:callToUpdate];
        }];

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
                [self.calls updateCall:call updateBlock:^(OCTCall *callToUpdate) {
                [callToUpdate startTimer];
                callToUpdate.status = OCTCallStatusActive;
            }];
                break;
            case OCTToxAVCallControlCancel:
                [self logCallAndStopTimer:call type:OCTMessageCallTypeEnd];
                [self.calls removeCall:call];
                return [self.audioEngine stopAudioFlow:error];
                break;
            case OCTToxAVCallControlPause:
                [self.calls updateCall:call updateBlock:^(OCTCall *callToUpdate) {
                [callToUpdate stopTimer];
                callToUpdate.status = OCTCallStatusPaused;
            }];
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
- (OCTCall *)callFromFriend:(OCTToxFriendNumber)friendNumber
{
    OCTDBManager *dbManager = [self.dataSource managerGetDBManager];
    OCTDBChat *chatDB = [dbManager getOrCreateChatWithFriendNumber:friendNumber];
    OCTChat *chat = [self.chatConverter objectFromRLMObject:chatDB];

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];

    return call;
}

- (void)setCallActiveAndStartTimer:(OCTCall *)call
{
    [self.calls updateCall:call updateBlock:^(OCTCall *callToUpdate) {
        callToUpdate.status = OCTCallStatusActive;
        [callToUpdate startTimer];
    }];
}

- (void)logCallAndStopTimer:(OCTCall *)call type:(OCTMessageCallType)type
{
    if (call.chat.friends.count == 1) {
        OCTFriend *friend = call.chat.friends.firstObject;
        [call stopTimer];

        OCTDBManager *dbManager = [self.dataSource managerGetDBManager];

        OCTDBChat *dbChat = [dbManager getOrCreateChatWithFriendNumber:friend.friendNumber];
        OCTDBFriend *dbFriend = [dbManager getOrCreateFriendWithFriendNumber:friend.friendNumber];

        OCTDBMessageAbstract *messageAbstract = [dbManager addMessageCallWithChat:dbChat
                                                                         callType:type
                                                                         duration:call.callDuration
                                                                           sender:dbFriend];
        [dbManager updateDBObjectInBlock:^{
            dbChat.lastMessage = messageAbstract;
        } objectClass:[OCTDBChat class]];
    }
}

#pragma mark OCTToxAV delegate methods

- (void)toxAV:(OCTToxAV *)toxAV receiveCallAudioEnabled:(BOOL)audio videoEnabled:(BOOL)video friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTCall *call = [self callFromFriend:friendNumber];
    call.status = OCTCallStatusIncoming;

    [self.calls addCall:call];

    if ([self.delegate respondsToSelector:@selector(callSubmanager:receiveCall:audioEnabled:videoEnabled:)]) {
        [self.delegate callSubmanager:self receiveCall:call audioEnabled:audio videoEnabled:video];
    }
}

- (void)toxAV:(OCTToxAV *)toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTCall *call = [self callFromFriend:friendNumber];

    if ((state & OCTToxAVCallStateError) || (state & OCTToxAVCallStateFinished)) {
        [self.calls updateCall:call updateBlock:^(OCTCall *callToUpdate) {
            [self logCallAndStopTimer:callToUpdate type:OCTMessageCallTypeEnd];
        }];
        [self.calls removeCall:call];
        [self.audioEngine stopAudioFlow:nil];
    }
    else {
        [self.calls updateCall:call updateBlock:^(OCTCall *callToUpdate) {
            if (callToUpdate.status == OCTCallStatusDialing) {
                [self.audioEngine startAudioFlow:nil];
                [callToUpdate startTimer];
            }
            callToUpdate.state = state;
            callToUpdate.status = OCTCallStatusActive;
        }];
    }
}

- (void)toxAV:(OCTToxAV *)toxAV audioBitRateChanged:(OCTToxAVAudioBitRate)bitrate stable:(BOOL)stable friendNumber:(OCTToxFriendNumber)friendNumber
{
    if ([self.delegate respondsToSelector:@selector(callSubmanager:audioBitRateChanged:stable:forCall:)]) {

        OCTCall *call = [self callFromFriend:friendNumber];

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

#pragma mark -  OCTConverterFriendDataSource

- (OCTTox *)converterFriendGetTox:(OCTConverterFriend *)converterFriend
{
    return [self.dataSource managerGetTox];
}

- (OCTDBManager *)converterFriendGetDBManager:(OCTConverterFriend *)converterFriend
{
    return [self.dataSource managerGetDBManager];
}

- (void)converterFriend:(OCTConverterFriend *)converter updateDBFriendWithBlock:(void (^)())block
{
    OCTDBManager *dbManager = [self.dataSource managerGetDBManager];

    [dbManager updateDBObjectInBlock:block objectClass:[OCTDBFriend class]];
}

#pragma mark -  OCTConverterChatDelegate

- (void)converterChat:(OCTConverterChat *)converter updateDBChatWithBlock:(void (^)())block
{
    OCTDBManager *dbManager = [self.dataSource managerGetDBManager];

    [dbManager updateDBObjectInBlock:block objectClass:[OCTDBChat class]];
}
@end
