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
 #import "OCTToxAV.h"
 #import "OCTTox.h"
 #import <OCMock/OCMock.h>

@interface OCTSubmanagerCalls (Tests)

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;
@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

- (OCTCall *)getOrCreateCallWithFriend:(OCTToxFriendNumber)friendNumber;

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
    XCTAssertNotNil(self.callManager.audioEngine);
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
    XCTAssertEqual(call.state, 0);
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

    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 12;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];
    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    OCTCall *call = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO error:nil];

    NSError *error;
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlCancel toCall:call error:&error]);

    OCMVerify([self.realmManager deleteObject:call]);
}

- (void)testAnswerCallFail
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;

    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 123;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTCall *call = [self.realmManager getOrCreateCallWithFriendNumber:123];

    XCTAssertFalse([self.callManager answerCall:call enableAudio:YES enableVideo:YES error:nil]);
    [OCMExpect([toxAV answerIncomingCallFromFriend:123 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]) ignoringNonObjectArgs];
}

- (void)testAnswerCallSuccess
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;

    id audioEngine = OCMPartialMock(self.callManager.audioEngine);
    OCMStub([audioEngine startAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);

    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 1234;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTCall *call = [self.realmManager getOrCreateCallWithFriendNumber:1234];

    OCMStub([toxAV answerIncomingCallFromFriend:1234 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES);

    XCTAssertTrue([self.callManager answerCall:call enableAudio:NO enableVideo:NO error:nil]);
    XCTAssertEqual(self.callManager.audioEngine.friendNumber, 1234);
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
}

- (void)testTogglePauseForCall
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;
    OCMStub([toxAV sendCallControl:OCTToxAVCallControlPause toFriendNumber:12345 error:nil]).andReturn(YES);

    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 12345;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTCall *call = [self.realmManager getOrCreateCallWithFriendNumber:12345];

    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlPause toCall:call error:nil]);

    OCMStub([toxAV sendCallControl:OCTToxAVCallControlResume toFriendNumber:12345 error:nil]).andReturn(YES);
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlResume toCall:call error:nil]);
}

- (void)testSetAudioBitRate
{
    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 123456;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTCall *call = [self.realmManager getOrCreateCallWithFriendNumber:123456];

    id toxAV = OCMClassMock([OCTToxAV class]);
    OCMStub([toxAV setAudioBitRate:5555 force:NO forFriend:123456 error:nil]).andReturn(YES);
    self.callManager.toxAV = toxAV;

    XCTAssertTrue([self.callManager setAudioBitrate:5555 forCall:call error:nil]);
    OCMVerify([toxAV setAudioBitRate:5555 force:NO forFriend:123456 error:nil]);
}

- (void)testSetVideoBitRate
{
    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 321;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTCall *call = [self.realmManager getOrCreateCallWithFriendNumber:321];

    id toxAV = OCMClassMock([OCTToxAV class]);
    OCMStub([toxAV setVideoBitRate:5555 force:NO forFriend:321 error:nil]).andReturn(YES);
    self.callManager.toxAV = toxAV;

    XCTAssertTrue([self.callManager setVideoBitrate:5555 forCall:call error:nil]);
    OCMVerify([toxAV setVideoBitRate:5555 force:NO forFriend:321 error:nil]);

}

#pragma mark - Private
- (void)testGetOrCreateCallWithFriend
{
    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 222;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    OCTCall *call = [self.realmManager getOrCreateCallWithFriendNumber:222];
    OCTCall *sameCall = [self.realmManager getOrCreateCallWithFriendNumber:222];

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

    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 221;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTCall *call = [self.realmManager getOrCreateCallWithFriendNumber:221];

    [self.callManager toxAV:nil receiveCallAudioEnabled:YES videoEnabled:NO friendNumber:221];
    OCMVerify([delegate callSubmanager:self.callManager receiveCall:call audioEnabled:YES videoEnabled:NO]);
}

- (void)testCallStateChanged
{
    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 111;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTCall *call = [self.realmManager getOrCreateCallWithFriendNumber:111];

    OCTToxAVCallState state;

    state |= OCTToxAVCallStateReceivingAudio;
    state |= OCTToxAVCallStateReceivingVideo;

    [self.callManager toxAV:nil callStateChanged:state friendNumber:111];

    call = [self.realmManager getOrCreateCallWithFriendNumber:111];

    XCTAssertEqual(call.state, state);
}

- (void)testAudioBitRateChanged
{
    id delegate = OCMProtocolMock(@protocol(OCTSubmanagerCallDelegate));
    OCMStub([delegate respondsToSelector:[OCMArg anySelector]]).andReturn(YES);
    self.callManager.delegate = delegate;

    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 777;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTCall *call = [self.realmManager getOrCreateCallWithFriendNumber:777];

    [self.callManager toxAV:nil audioBitRateChanged:999 stable:NO friendNumber:777];
    OCMVerify([delegate callSubmanager:[OCMArg any] audioBitRateChanged:999 stable:NO forCall:call]);
}

- (void)testReceiveAudio
{
    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    self.callManager.audioEngine = audioEngine;

    OCTToxAVPCMData pcm[] = { 1, 2, 3, 4};

    [self.callManager toxAV:nil receiveAudio:pcm sampleCount:4 channels:2 sampleRate:55 friendNumber:123];

    OCMVerify([audioEngine provideAudioFrames:pcm sampleCount:4 channels:2 sampleRate:55]);
}

@end
