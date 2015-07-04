//
//  OCTSubmanagerCallsTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/4/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCTRealmTests.h"

#import "OCTSubmanagerCalls+Private.h"
#import "OCTRealmManager.h"
#import "OCTAudioEngine.h"
#import "OCTMessageCall.h"
#import "OCTMessageAbstract.h"
#import "OCTToxAV.h"
#import "OCTTox.h"
#import <OCMock/OCMock.h>

@interface OCTSubmanagerCalls (Tests)

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;
@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;
@property (strong, nonatomic) OCTCallTimer *timer;

- (OCTCall *)getOrCreateCallWithFriendNumber:(OCTToxFriendNumber)friendNumber;

- (void)toxAV:(OCTToxAV *)toxAV receiveCallAudioEnabled:(BOOL)audio videoEnabled:(BOOL)video friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)toxAV:(OCTToxAV *)toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)toxAV:(OCTToxAV *)toxAV audioBitRateChanged:(OCTToxAVAudioBitRate)bitrate stable:(BOOL)stable friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)   toxAV:(OCTToxAV *)toxAV
    receiveAudio:(OCTToxAVPCMData *)pcm
     sampleCount:(OCTToxAVSampleCount)sampleCount
        channels:(OCTToxAVChannels)channels
      sampleRate:(OCTToxAVSampleRate)sampleRate
    friendNumber:(OCTToxFriendNumber)friendNumber;

@end

@interface OCTSubmanagerCallsTests : OCTRealmTests

@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) OCTSubmanagerCalls *callManager;
@property (strong, nonatomic) OCTTox *tox;

@end

@implementation OCTSubmanagerCallsTests

- (void)setUp
{
    [super setUp];
    self.tox = [[OCTTox alloc] initWithOptions:[OCTToxOptions new] savedData:nil error:nil];
    self.callManager = [[OCTSubmanagerCalls alloc] initWithTox:self.tox];

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));
    OCMStub([self.dataSource managerGetRealmManager]).andReturn(self.realmManager);

    self.callManager.dataSource = self.dataSource;
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.callManager = nil;
    self.tox = nil;
    self.dataSource = nil;
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.callManager);
}

- (void)testSetup
{
    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    OCMStub([audioEngine new]).andReturn(audioEngine);
    OCMStub([audioEngine setupWithError:[OCMArg anyObjectRef]]).andReturn(YES);
    self.callManager.audioEngine = audioEngine;

    XCTAssertTrue([self.callManager setupWithError:nil]);
}

- (void)testCallToChat
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    [OCMStub([toxAV callFriendNumber:1
                        audioBitRate:0
                        videoBitRate:0
                               error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    self.callManager.toxAV = toxAV;

    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 1;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    OCTCall *call = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO error:nil];

    XCTAssertNotNil(call.chat);

    XCTAssertEqualObjects(call.chat, chat);
    XCTAssertEqual(call.status, OCTCallStatusDialing);
    XCTAssertTrue(call.isOutgoing);
}

- (void)testEndCall
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    [OCMStub([toxAV callFriendNumber:12 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    OCMStub([toxAV sendCallControl:OCTToxAVCallControlCancel toFriendNumber:12 error:[OCMArg anyObjectRef]]).andReturn(YES);
    self.callManager.toxAV = toxAV;

    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    OCMStub([audioEngine stopAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);
    self.callManager.audioEngine = audioEngine;

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

- (void)testAnswerCallFail
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;

    [self createFriendWithFriendNumber:123];

    OCTCall *call = [self.callManager getOrCreateCallWithFriendNumber:123];

    XCTAssertFalse([self.callManager answerCall:call enableAudio:YES enableVideo:YES error:nil]);
    [OCMExpect([toxAV answerIncomingCallFromFriend:123 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]) ignoringNonObjectArgs];
}

- (void)testAnswerCallSuccess
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;

    self.callManager.audioEngine = [OCTAudioEngine new];
    id audioEngine = OCMPartialMock(self.callManager.audioEngine);
    OCMStub([audioEngine startAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);

    [self createFriendWithFriendNumber:1234];

    OCTCall *call = [self.callManager getOrCreateCallWithFriendNumber:1234];

    OCMStub([toxAV answerIncomingCallFromFriend:1234 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES);

    XCTAssertTrue([self.callManager answerCall:call enableAudio:NO enableVideo:NO error:nil]);
    XCTAssertEqual(self.callManager.audioEngine.friendNumber, 1234);
}

- (void)testCallStateReceiveFinished
{
    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    self.callManager.audioEngine = audioEngine;

    OCTFriend *friend = [self createFriendWithFriendNumber:89];

    OCTCall *call = [self.callManager getOrCreateCallWithFriendNumber:89];
    [self.realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        callToUpdate.status = OCTCallStatusRinging;
    }];

    OCTToxAVCallState state;
    state |= OCTToxAVFriendCallStateFinished;

    [self.callManager toxAV:nil callStateChanged:state friendNumber:89];

    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    OCMVerify([audioEngine stopAudioFlow:nil]);
    XCTAssertNotNil(chat.lastMessage.messageCall);
    XCTAssertEqual(chat.lastMessage.messageCall.callEvent, OCTMessageCallEventUnanswered);

    call = [self.callManager getOrCreateCallWithFriendNumber:89];
    [self.realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        call.status = OCTCallStatusActive;
    }];

    [self.callManager toxAV:nil callStateChanged:state friendNumber:89];

    XCTAssertEqual(chat.lastMessage.messageCall.callEvent, OCTMessageCallEventAnswered);
    XCTAssertFalse(chat.lastMessage.messageCall.isOutgoing);
}

- (void)testFriendAnsweredCall
{
    id timer = OCMClassMock([OCTCallTimer class]);
    self.callManager.timer = timer;

    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    self.callManager.audioEngine = audioEngine;

    [self createFriendWithFriendNumber:92];

    OCTCall *call = [self.callManager getOrCreateCallWithFriendNumber:92];
    [self.realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        callToUpdate.status = OCTCallStatusDialing;
    }];

    OCTToxAVCallState state;
    state |= OCTToxAVFriendCallStateReceivingVideo;

    [self.callManager toxAV:nil callStateChanged:state friendNumber:92];

    OCMVerify([audioEngine startAudioFlow:nil]);
    OCMVerify([audioEngine setFriendNumber:92]);
    OCMVerify([timer startTimerForCall:call]);

    XCTAssertEqual(call.status, OCTCallStatusActive);
    XCTAssertTrue(call.receivingVideo);

}

- (void)testRouteAudioToSpeaker
{
    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    self.callManager.audioEngine = audioEngine;

    [self.callManager routeAudioToSpeaker:YES error:nil];

    OCMVerify([audioEngine routeAudioToSpeaker:YES error:nil]);
}

- (void)testEnableMicrophone
{
    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    self.callManager.audioEngine = audioEngine;

    [self.callManager setEnableMicrophone:NO];

    OCMVerify([audioEngine setEnableMicrophone:NO]);

    XCTAssertFalse(self.callManager.enableMicrophone);
}

- (void)testTogglePauseForCall
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;
    OCMStub([toxAV sendCallControl:OCTToxAVCallControlPause toFriendNumber:12345 error:nil]).andReturn(YES);

    [self createFriendWithFriendNumber:12345];

    OCTCall *call = [self.callManager getOrCreateCallWithFriendNumber:12345];

    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlPause toCall:call error:nil]);

    OCMStub([toxAV sendCallControl:OCTToxAVCallControlResume toFriendNumber:12345 error:nil]).andReturn(YES);
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlResume toCall:call error:nil]);
}

- (void)testSetAudioBitRate
{
    [self createFriendWithFriendNumber:123456];

    OCTCall *call = [self.callManager getOrCreateCallWithFriendNumber:123456];

    id toxAV = OCMClassMock([OCTToxAV class]);
    OCMStub([toxAV setAudioBitRate:5555 force:NO forFriend:123456 error:nil]).andReturn(YES);
    self.callManager.toxAV = toxAV;

    XCTAssertTrue([self.callManager setAudioBitrate:5555 forCall:call error:nil]);
    OCMVerify([toxAV setAudioBitRate:5555 force:NO forFriend:123456 error:nil]);
}

- (void)testSetVideoBitRate
{
    [self createFriendWithFriendNumber:321];

    OCTCall *call = [self.callManager getOrCreateCallWithFriendNumber:321];

    id toxAV = OCMClassMock([OCTToxAV class]);
    OCMStub([toxAV setVideoBitRate:5555 force:NO forFriend:321 error:nil]).andReturn(YES);
    self.callManager.toxAV = toxAV;

    XCTAssertTrue([self.callManager setVideoBitrate:5555 forCall:call error:nil]);
    OCMVerify([toxAV setVideoBitRate:5555 force:NO forFriend:321 error:nil]);
}

#pragma mark - Private
- (void)testGetOrCreateCallWithFriend
{
    OCTFriend *friend = [self createFriendWithFriendNumber:222];

    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    OCTCall *call = [self.callManager getOrCreateCallWithFriendNumber:222];
    OCTCall *sameCall = [self.callManager getOrCreateCallWithFriendNumber:222];

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

    [self createFriendWithFriendNumber:221];

    OCTCall *call = [self.callManager getOrCreateCallWithFriendNumber:221];

    [self.callManager toxAV:nil receiveCallAudioEnabled:YES videoEnabled:NO friendNumber:221];
    OCMVerify([delegate callSubmanager:self.callManager receiveCall:call audioEnabled:YES videoEnabled:NO]);
    XCTAssertFalse(call.isOutgoing);
}

- (void)testCallStateChanged
{
    [self createFriendWithFriendNumber:111];

    OCTCall *call = [self.callManager getOrCreateCallWithFriendNumber:111];

    OCTToxAVCallState state;

    state |= OCTToxAVFriendCallStateReceivingAudio;
    state |= OCTToxAVFriendCallStateReceivingVideo;

    [self.callManager toxAV:nil callStateChanged:state friendNumber:111];

    call = [self.callManager getOrCreateCallWithFriendNumber:111];

    XCTAssertTrue(call.receivingAudio);
    XCTAssertTrue(call.receivingVideo);
    XCTAssertFalse(call.sendingAudio);
    XCTAssertFalse(call.sendingVideo);
}

- (void)testReceiveAudio
{
    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    self.callManager.audioEngine = audioEngine;

    OCTToxAVPCMData pcm[] = { 1, 2, 3, 4};

    [self.callManager toxAV:nil receiveAudio:pcm sampleCount:4 channels:2 sampleRate:55 friendNumber:123];

    OCMVerify([audioEngine provideAudioFrames:pcm sampleCount:4 channels:2 sampleRate:55]);
}

- (void)testReceiveUnstableBitrate
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;

    [self.callManager toxAV:toxAV audioBitRateChanged:48 stable:NO friendNumber:1234];
    OCMVerify([toxAV setAudioBitRate:32 force:NO forFriend:1234 error:nil]);

    [self.callManager toxAV:toxAV audioBitRateChanged:32 stable:NO friendNumber:1234];
    OCMVerify([toxAV setAudioBitRate:24 force:NO forFriend:1234 error:nil]);

    [self.callManager toxAV:toxAV audioBitRateChanged:24 stable:NO friendNumber:1234];
    OCMVerify([toxAV setAudioBitRate:16 force:NO forFriend:1234 error:nil]);

    [self.callManager toxAV:toxAV audioBitRateChanged:16 stable:NO friendNumber:1234];
    OCMVerify([toxAV setAudioBitRate:8 force:NO forFriend:1234 error:nil]);
}

#pragma mark Test helper methods
- (OCTFriend *)createFriendWithFriendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTFriend *friend = [self createFriend];
    friend.friendNumber = friendNumber;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    return friend;
}

@end
