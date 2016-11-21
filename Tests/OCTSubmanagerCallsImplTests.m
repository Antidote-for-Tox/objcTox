// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <XCTest/XCTest.h>

#import "OCTRealmTests.h"

#import "OCTSubmanagerCallsImpl.h"
#import "OCTRealmManager.h"
#import "OCTAudioEngine.h"
#import "OCTMessageCall.h"
#import "OCTMessageAbstract.h"
#import "OCTToxAV.h"
#import "OCTTox.h"
#import <OCMock/OCMock.h>

@import AVFoundation;

@interface OCTSubmanagerCallsImpl (Tests)

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;
@property (strong, nonatomic) OCTVideoEngine *videoEngine;
@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;
@property (strong, nonatomic) OCTCallTimer *timer;

- (void)toxAV:(OCTToxAV *)toxAV receiveCallAudioEnabled:(BOOL)audio videoEnabled:(BOOL)video friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)toxAV:(OCTToxAV *)toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)toxAV:(OCTToxAV *)toxAV audioBitRateChanged:(OCTToxAVAudioBitRate)bitrate stable:(BOOL)stable friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)   toxAV:(OCTToxAV *)toxAV
    receiveAudio:(OCTToxAVPCMData *)pcm
     sampleCount:(OCTToxAVSampleCount)sampleCount
        channels:(OCTToxAVChannels)channels
      sampleRate:(OCTToxAVSampleRate)sampleRate
    friendNumber:(OCTToxFriendNumber)friendNumber;

- (void)                 toxAV:(OCTToxAV *)toxAV
    receiveVideoFrameWithWidth:(OCTToxAVVideoWidth)width height:(OCTToxAVVideoHeight)height
                        yPlane:(OCTToxAVPlaneData *)yPlane uPlane:(OCTToxAVPlaneData *)uPlane
                        vPlane:(OCTToxAVPlaneData *)vPlane
                       yStride:(OCTToxAVStrideData)yStride uStride:(OCTToxAVStrideData)uStride
                       vStride:(OCTToxAVStrideData)vStride
                  friendNumber:(OCTToxFriendNumber)friendNumber;

- (OCTCall *)createCallWithFriend:(OCTFriend *)friend status:(OCTCallStatus)status;
- (OCTCall *)getCurrentCallForFriendNumber:(OCTToxFriendNumber)friendNumber;

@end

@interface OCTSubmanagerCallsImplTests : OCTRealmTests

@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) OCTSubmanagerCallsImpl *callManager;
@property (strong, nonatomic) OCTTox *tox;
@property (strong, nonatomic) id mockedAudioEngine;
@property (strong, nonatomic) id mockedVideoEngine;
@property (strong, nonatomic) id mockedToxAV;

@end

@implementation OCTSubmanagerCallsImplTests

- (void)setUp
{
    [super setUp];
    self.tox = [[OCTTox alloc] initWithOptions:[OCTToxOptions new] savedData:nil error:nil];
    self.tox = OCMPartialMock(self.tox);
    self.callManager = [[OCTSubmanagerCallsImpl alloc] initWithTox:self.tox];

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));
    OCMStub([self.dataSource managerGetRealmManager]).andReturn(self.realmManager);
    OCMStub([self.dataSource managerGetTox]).andReturn(self.tox);

    OCTAudioEngine *audioEngine = [OCTAudioEngine new];
    self.mockedAudioEngine = OCMPartialMock(audioEngine);
    self.callManager.audioEngine = self.mockedAudioEngine;

    OCTVideoEngine *videoEngine = [OCTVideoEngine new];
    self.mockedVideoEngine = OCMPartialMock(videoEngine);
    self.callManager.videoEngine = self.mockedVideoEngine;

    self.mockedToxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = self.mockedToxAV;

    self.callManager.dataSource = self.dataSource;
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [self.dataSource stopMocking];
    [self.mockedAudioEngine stopMocking];
    [self.mockedVideoEngine stopMocking];
    [self.mockedToxAV stopMocking];
    [(id)self.tox stopMocking];
    self.dataSource = nil;
    self.callManager = nil;
    self.tox = nil;
    self.mockedAudioEngine = nil;
    self.mockedToxAV = nil;
    self.mockedVideoEngine = nil;
    [super tearDown];
}

- (void)testInit
{
    id tox = OCMClassMock([OCTTox class]);
    OCMStub([self.mockedToxAV alloc]).andReturn(self.mockedToxAV);
    OCMStub([self.mockedToxAV initWithTox:tox error:nil]).andReturn(self.mockedToxAV);

    OCTSubmanagerCallsImpl *manager = [[OCTSubmanagerCallsImpl alloc] initWithTox:tox];

    XCTAssertNotNil(manager);
    OCMVerify([(OCTToxAV *)self.mockedToxAV start]);

    [tox stopMocking];
}

- (void)testSetup
{
    OCMStub([self.mockedAudioEngine new]).andReturn(self.mockedAudioEngine);

    OCMStub([self.mockedVideoEngine new]).andReturn(self.mockedVideoEngine);
    OCMStub([self.mockedVideoEngine setupAndReturnError:[OCMArg anyObjectRef]]).andReturn(YES);

    XCTAssertTrue([self.callManager setupAndReturnError:nil]);

    OCMVerify([self.mockedVideoEngine setupAndReturnError:[OCMArg anyObjectRef]]);
}

- (void)testCallToChat
{
    [OCMStub([self.mockedToxAV callFriendNumber:1
                                   audioBitRate:0
                                   videoBitRate:0
                                          error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];

    OCTFriend *friend = [self createFriendWithFriendNumber:1];

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    OCTCall *call = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO error:nil];

    XCTAssertNotNil(call.chat);

    XCTAssertEqualObjects(call.chat, chat);
    XCTAssertEqual(call.status, OCTCallStatusDialing);
    XCTAssertNil(call.caller);
    XCTAssertTrue([call isOutgoing]);
}

- (void)testEnableVideoForCall
{
    id partialMockedVideoEngine = OCMPartialMock([OCTVideoEngine new]);
    self.callManager.videoEngine = partialMockedVideoEngine;
    [self.mockedVideoEngine setExpectationOrderMatters:YES];
    OCMExpect([partialMockedVideoEngine startSendingVideo]);
    OCMExpect([partialMockedVideoEngine stopSendingVideo]);

    [OCMStub([self.mockedToxAV setVideoBitRate:123 force:YES forFriend:987 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    OCTFriend *friend = [self createFriendWithFriendNumber:987];
    OCTCall *call = [self.callManager createCallWithFriend:friend status:OCTCallStatusActive];

    XCTAssertTrue([self.callManager enableVideoSending:YES forCall:call error:nil]);
    XCTAssertTrue(call.videoIsEnabled);
    XCTAssertEqual(self.callManager.videoEngine.friendNumber, 987);

    XCTAssertTrue([self.callManager enableVideoSending:NO forCall:call error:nil]);
    XCTAssertFalse(call.videoIsEnabled);

    OCMVerifyAll(partialMockedVideoEngine);
}

- (void)testEndCall
{
    OCMStub([self.mockedToxAV callFriendNumber:12 audioBitRate:48 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.mockedToxAV sendCallControl:OCTToxAVCallControlCancel toFriendNumber:12 error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.mockedAudioEngine stopAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);

    OCTFriend *friend = [self createFriendWithFriendNumber:12];
    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    OCTCall *call = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO error:nil];

    NSError *error;
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlCancel toCall:call error:&error]);

    OCMVerify([self.realmManager deleteObject:call]);

    XCTAssertNotNil(chat.lastMessage.messageCall);
    XCTAssertEqual(chat.lastMessage.messageCall.callEvent, OCTMessageCallEventUnanswered);
    XCTAssertTrue(chat.lastMessage.isOutgoing);
}

- (void)testAnswerCallSuccess
{
    OCMStub([self.mockedAudioEngine startAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);

    OCTFriend *friend = [self createFriendWithFriendNumber:1234];

    OCTCall *call = [self.callManager createCallWithFriend:friend status:OCTCallStatusRinging];

    OCMStub([self.mockedToxAV answerIncomingCallFromFriend:1234 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES);

    XCTAssertTrue([self.callManager answerCall:call enableAudio:NO enableVideo:NO error:nil]);
    XCTAssertEqual(self.callManager.audioEngine.friendNumber, 1234);
}

- (void)testCallStateReceiveFinished
{
    OCMStub([self.mockedAudioEngine isAudioRunning:nil]).andReturn(NO);
    OCMStub([self.mockedAudioEngine friendNumber]).andReturn(89);

    OCTFriend *friend = [self createFriendWithFriendNumber:89];

    OCTCall *call = [self.callManager createCallWithFriend:friend status:OCTCallStatusDialing];
    [self.realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        callToUpdate.status = OCTCallStatusRinging;
    }];

    OCTToxAVCallState state = 0;
    state |= OCTToxAVFriendCallStateFinished;

    [self.callManager toxAV:nil callStateChanged:state friendNumber:89];

    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    XCTAssertNotNil(chat.lastMessage.messageCall);
    XCTAssertEqual(chat.lastMessage.messageCall.callEvent, OCTMessageCallEventUnanswered);

    call = [self.callManager createCallWithFriend:friend status:OCTCallStatusRinging];
    [self.realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        call.status = OCTCallStatusActive;
    }];

    [self.callManager toxAV:nil callStateChanged:state friendNumber:89];

    XCTAssertEqual(chat.lastMessage.messageCall.callEvent, OCTMessageCallEventAnswered);
}

- (void)testFriendAnsweredCall
{
    id timer = OCMClassMock([OCTCallTimer class]);
    self.callManager.timer = timer;

    OCTFriend *friend = [self createFriendWithFriendNumber:92];

    OCTCall *call = [self.callManager createCallWithFriend:friend status:OCTCallStatusRinging];
    [self.realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        callToUpdate.status = OCTCallStatusDialing;
    }];

    OCTToxAVCallState state = 0;
    state |= OCTToxAVFriendCallStateAcceptingVideo;

    OCMStub([self.mockedAudioEngine startAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);
    [self.callManager toxAV:nil callStateChanged:state friendNumber:92];

    OCMVerify([self.mockedAudioEngine startAudioFlow:[OCMArg anyObjectRef]]);
    OCMVerify([self.mockedAudioEngine setFriendNumber:92]);
    OCMVerify([timer startTimerForCall:[OCMArg isNotNil]]);

    XCTAssertEqual(call.status, OCTCallStatusActive);
    XCTAssertTrue(call.friendAcceptingVideo);
}

- (void)testEnableMicrophone
{
    [self.callManager setEnableMicrophone:NO];

    OCMVerify([self.mockedAudioEngine setEnableMicrophone:NO]);

    XCTAssertFalse(self.callManager.enableMicrophone);
}

- (void)testTogglePauseForCall
{
    OCMStub([self.mockedToxAV sendCallControl:OCTToxAVCallControlPause toFriendNumber:12345 error:nil]).andReturn(YES);
    id partialMockedAudioEngine = OCMPartialMock([OCTAudioEngine new]);
    self.callManager.audioEngine = partialMockedAudioEngine;
    self.callManager.audioEngine.friendNumber = 12345;

    OCTFriend *friend = [self createFriendWithFriendNumber:12345];

    OCTCall *call = [self.callManager createCallWithFriend:friend status:OCTCallStatusActive];
    [self.realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        callToUpdate.videoIsEnabled = YES;
    }];

    OCMStub([self.mockedVideoEngine isSendingVideo]).andReturn(YES);
    OCMStub([partialMockedAudioEngine isAudioRunning:nil]).andReturn(YES);
    OCMStub([self.mockedVideoEngine stopSendingVideo]);
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlPause toCall:call error:nil]);

    OCMStub([self.mockedVideoEngine startSendingVideo]);
    OCMVerify([self.mockedVideoEngine stopSendingVideo]);
    OCMVerify([partialMockedAudioEngine stopAudioFlow:nil]);

    OCMStub([partialMockedAudioEngine isAudioRunning:nil]).andReturn(NO);
    OCMStub([self.mockedVideoEngine isSendingVideo]).andReturn(NO);

    OCMStub([self.mockedToxAV sendCallControl:OCTToxAVCallControlResume toFriendNumber:12345 error:nil]).andReturn(YES);
    OCMStub([partialMockedAudioEngine startAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlResume toCall:call error:nil]);

    OCMVerify([self.mockedVideoEngine startSendingVideo]);
    OCMVerify([partialMockedAudioEngine startAudioFlow:[OCMArg anyObjectRef]]);
}

- (void)testSetAudioBitRate
{
    OCTFriend *friend = [self createFriendWithFriendNumber:123456];

    OCTCall *call = [self.callManager createCallWithFriend:friend status:OCTCallStatusActive];

    OCMStub([self.mockedToxAV setAudioBitRate:5555 force:NO forFriend:123456 error:nil]).andReturn(YES);

    XCTAssertTrue([self.callManager setAudioBitrate:5555 forCall:call error:nil]);
    OCMVerify([self.mockedToxAV setAudioBitRate:5555 force:NO forFriend:123456 error:nil]);
}

#pragma mark - Pause Scenarios

- (void)testAnsweringAnotherCallWhileActive
{
    [OCMStub([self.mockedToxAV sendCallControl:123 toFriendNumber:123 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    [OCMStub([self.mockedToxAV answerIncomingCallFromFriend:123 audioBitRate:48 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    [self.mockedToxAV setExpectationOrderMatters:YES];
    OCMExpect([self.mockedToxAV sendCallControl:OCTToxAVCallControlPause toFriendNumber:4 error:[OCMArg anyObjectRef]]);
    OCMExpect([self.mockedToxAV answerIncomingCallFromFriend:5 audioBitRate:48 videoBitRate:0 error:[OCMArg anyObjectRef]]);

    OCMStub([self.callManager.audioEngine isAudioRunning:nil]).andReturn(YES);
    OCMStub([self.callManager.audioEngine stopAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.callManager.audioEngine startAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);

    OCTFriend *firstFriend = [self createFriendWithFriendNumber:4];
    OCTFriend *secondFriend = [self createFriendWithFriendNumber:5];
    OCTCall *firstCall = [self.callManager createCallWithFriend:firstFriend status:OCTCallStatusActive];
    self.callManager.audioEngine.friendNumber = 4;

    // create incoming call
    OCTCall *secondCall = [self.callManager createCallWithFriend:secondFriend status:OCTCallStatusRinging];

    // mock call timer
    id mockedTimer = OCMClassMock([OCTCallTimer class]);
    [mockedTimer setExpectationOrderMatters:YES];
    OCMExpect([mockedTimer stopTimer]);
    OCMExpect([mockedTimer startTimerForCall:[OCMArg isNotNil]]);

    self.callManager.timer = mockedTimer;

    [self.callManager answerCall:secondCall enableAudio:YES enableVideo:NO error:nil];

    XCTAssertEqual(secondCall.status, OCTCallStatusActive);
    XCTAssertEqual(secondCall.pausedStatus, OCTCallPausedStatusNone);
    XCTAssertEqual(self.callManager.audioEngine.friendNumber, 5);

    XCTAssertEqual(firstCall.status, OCTCallStatusActive);
    XCTAssertEqual(firstCall.pausedStatus, OCTCallPausedStatusByUser);

    OCMVerifyAll(mockedTimer);
    OCMVerifyAll(self.mockedAudioEngine);
}

- (void)testPauseControlPermissions
{
    OCTFriend *friend = [self createFriendWithFriendNumber:11];

    OCTCall *call = [self.callManager createCallWithFriend:friend status:OCTCallStatusActive];

    id mockedTimer = OCMClassMock([OCTCallTimer class]);
    [mockedTimer setExpectationOrderMatters:YES];
    self.callManager.timer = mockedTimer;
    OCMExpect([mockedTimer stopTimer]);
    OCMExpect([mockedTimer startTimerForCall:[OCMArg isNotNil]]);

    [self.callManager toxAV:nil callStateChanged:OCTToxAVFriendCallStatePaused friendNumber:11];

    XCTAssertEqual(call.pausedStatus, OCTCallPausedStatusByFriend);
    XCTAssertEqual(call.status, OCTCallStatusActive);

    id strictMockedTimer = OCMStrictClassMock([OCTCallTimer class]);
    self.callManager.timer = strictMockedTimer;

    OCMStub([self.mockedToxAV sendCallControl:OCTToxAVCallControlResume toFriendNumber:11 error:[OCMArg anyObjectRef]]).andReturn(YES);
    [self.callManager sendCallControl:OCTToxAVCallControlResume toCall:call error:nil];

    XCTAssertEqual(call.pausedStatus, OCTCallPausedStatusByFriend);

    OCMStub([self.mockedToxAV sendCallControl:OCTToxAVCallControlPause toFriendNumber:11 error:[OCMArg anyObjectRef]]).andReturn(YES);
    [self.callManager sendCallControl:OCTToxAVCallControlPause toCall:call error:nil];

    XCTAssertEqual(call.pausedStatus, OCTCallPausedStatusByFriend | OCTCallPausedStatusByUser);

    [self.callManager toxAV:nil callStateChanged:OCTToxAVFriendCallStateAcceptingAudio friendNumber:11];
    XCTAssertEqual(call.pausedStatus, OCTCallPausedStatusByUser);

    self.callManager.timer = mockedTimer;

    OCMStub([self.mockedAudioEngine startAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);
    [self.callManager sendCallControl:OCTToxAVCallControlResume toCall:call error:nil];
    XCTAssertEqual(call.pausedStatus, OCTCallPausedStatusNone);

    OCMVerifyAll(mockedTimer);
}

#pragma mark - Private
- (void)testGetOrCreateCallWithFriend
{
    OCTFriend *friend = [self createFriendWithFriendNumber:222];

    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    OCTCall *call = [self.callManager createCallWithFriend:friend status:OCTCallStatusActive];
    OCTCall *sameCall = [self.callManager getCurrentCallForFriendNumber:222];

    XCTAssertNotNil(call.chat);
    XCTAssertEqualObjects(call.chat, chat);
    XCTAssertEqualObjects(sameCall, call);
}

 #pragma mark - Delegates

- (void)testReceiveCalls
{
    id delegate = OCMProtocolMock(@protocol(OCTSubmanagerCallDelegate));
    OCMStub([delegate respondsToSelector:[OCMArg anySelector]]).andReturn(YES);
    self.callManager.delegate = delegate;

    OCTFriend *friend = [self createFriendWithFriendNumber:221];

    OCTCall *call = [self.callManager createCallWithFriend:friend status:OCTCallStatusActive];

    [self.callManager toxAV:nil receiveCallAudioEnabled:YES videoEnabled:NO friendNumber:221];
    OCMVerify([delegate callSubmanager:self.callManager receiveCall:[OCMArg isNotNil] audioEnabled:YES videoEnabled:NO]);
    XCTAssertEqualObjects(friend, call.caller);
    XCTAssertFalse([call isOutgoing]);
}

- (void)testCallStateChanged
{
    OCTFriend *friend = [self createFriendWithFriendNumber:111];

    OCTCall *call = [self.callManager createCallWithFriend:friend status:OCTCallStatusActive];

    OCTToxAVCallState state = 0;

    state |= OCTToxAVFriendCallStateAcceptingAudio;
    state |= OCTToxAVFriendCallStateAcceptingVideo;

    [self.callManager toxAV:nil callStateChanged:state friendNumber:111];

    call = [self.callManager getCurrentCallForFriendNumber:111];

    XCTAssertTrue(call.friendAcceptingAudio);
    XCTAssertTrue(call.friendAcceptingVideo);
    XCTAssertFalse(call.friendSendingAudio);
    XCTAssertFalse(call.friendSendingVideo);
}

- (void)testReceiveAudio
{
    OCTToxAVPCMData pcm[] = { 1, 2, 3, 4};

    [self.callManager toxAV:nil receiveAudio:pcm sampleCount:4 channels:2 sampleRate:55 friendNumber:123];

    OCMVerify([self.mockedAudioEngine provideAudioFrames:pcm sampleCount:4 channels:2 sampleRate:55 fromFriend:123]);
}

- (void)testReceiveVideo
{
    OCTToxAVVideoHeight height = 1920;
    OCTToxAVVideoHeight width = 1080;
    OCTToxAVPlaneData y[] = {5, 5, 6, 8};
    OCTToxAVPlaneData u[] = {5, 5, 6, 8};
    OCTToxAVPlaneData v[] = {5, 5, 6, 8};
    OCTToxAVStrideData yStride = 44;
    OCTToxAVStrideData uStride = 45;
    OCTToxAVStrideData vStride = 46;

    [self.callManager toxAV:nil
     receiveVideoFrameWithWidth:width
                         height:height
                         yPlane:y
                         uPlane:u
                         vPlane:v
                        yStride:yStride
                        uStride:uStride
                        vStride:vStride
                   friendNumber:444];

    OCMVerify([self.mockedVideoEngine receiveVideoFrameWithWidth:width
                                                          height:height
                                                          yPlane:y
                                                          uPlane:u
                                                          vPlane:v
                                                         yStride:yStride
                                                         uStride:uStride
                                                         vStride:vStride
                                                    friendNumber:444]);
}

#pragma mark Test helper methods

- (OCTFriend *)createFriendWithFriendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTFriend *friend = [super createFriendWithFriendNumber:friendNumber];
    friend.friendNumber = friendNumber;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:friendNumber error:nil]).andReturn(publicKey);

    return friend;
}

@end
