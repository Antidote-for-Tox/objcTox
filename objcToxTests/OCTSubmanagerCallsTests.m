//
//  OCTSubmanagerCallsTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/4/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCTSubmanagerCalls+Private.h"
#import "OCTAudioEngine.h"
#import "OCTToxAV.h"
#import "OCTTox.h"
#import "OCTCall+Private.h"
#import <OCMock/OCMock.h>

@interface OCTSubmanagerCalls (Tests)

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;
@property (strong, nonatomic, readwrite) NSMutableArray *calls;
@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

- (OCTCall *)getOrCreateCallFromFriend:(OCTToxFriendNumber)friendNumber;

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

@interface OCTSubmanagerCallsTests : XCTestCase

@property (strong, nonatomic) OCTTox *tox;
@property (strong, nonatomic) OCTSubmanagerCalls *callManager;

@end

@implementation OCTSubmanagerCallsTests

- (void)setUp
{
    [super setUp];

    self.tox = [[OCTTox alloc] initWithOptions:[OCTToxOptions new] savedData:nil error:nil];
    self.callManager = [[OCTSubmanagerCalls alloc] initWithTox:self.tox];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.callManager = nil;
    self.tox = nil;
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.callManager);
    XCTAssertNotNil(self.callManager.audioEngine);
    XCTAssertEqual(0, [self.callManager.allCalls count]);
}

- (void)testCallToChat
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    [OCMStub([toxAV callFriendNumber:1234 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    self.callManager.toxAV = toxAV;

    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;

    OCTChat *chat = [OCTChat new];
    chat.friends = (RLMArray<OCTFriend> *)(@[friend]);

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    OCTCall *callResult = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO error:nil];

    XCTAssertEqualObjects(call, callResult);
    XCTAssertEqual([self.callManager.calls count], 1);
}

- (void)testEndCall
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    [OCMStub([toxAV callFriendNumber:1234 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    OCMStub([toxAV sendCallControl:OCTToxAVCallControlCancel toFriendNumber:1234 error:[OCMArg anyObjectRef]]).andReturn(YES);
    self.callManager.toxAV = toxAV;

    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    OCMStub([audioEngine stopAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);
    self.callManager.audioEngine = audioEngine;

    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = (RLMArray<OCTFriend> *)(@[friend]);

    OCTCall *call = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO error:nil];

    XCTAssertEqual(self.callManager.calls.count, 1);

    NSError *error;
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlCancel toCall:call error:&error]);

    XCTAssertEqual(0, self.callManager.calls.count);
}

- (void)testAnswerCallFail
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;

    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    call.status = OCTCallStatusIncoming;

    XCTAssertFalse([self.callManager answerCall:call enableAudio:YES enableVideo:YES error:nil]);
    [OCMExpect([toxAV answerIncomingCallFromFriend:1234 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]) ignoringNonObjectArgs];
}

- (void)testAnswerCallSuccess
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;

    id audioEngine = OCMPartialMock(self.callManager.audioEngine);
    OCMStub([audioEngine startAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);

    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = (RLMArray<OCTFriend> *)(@[friend]);

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    call.status = OCTCallStatusIncoming;
    [self.callManager.calls addObject:call];

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
    OCMStub([toxAV sendCallControl:OCTToxAVCallControlPause toFriendNumber:1234 error:nil]).andReturn(YES);
    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = (RLMArray<OCTFriend> *)(@[friend]);

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    call.status = OCTCallStatusInSession;
    [self.callManager.calls addObject:call];

    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlPause toCall:call error:nil]);

    OCMStub([toxAV sendCallControl:OCTToxAVCallControlResume toFriendNumber:1234 error:nil]).andReturn(YES);
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlResume toCall:call error:nil]);
    OCTCall *otherCall = [self.callManager.calls objectAtIndex:0];
    XCTAssertEqual(otherCall.status, OCTCallStatusInSession);
}

- (void)testSetAudioBitRate
{
    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = (RLMArray<OCTFriend> *)(@[friend]);

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];

    id toxAV = OCMClassMock([OCTToxAV class]);
    OCMStub([toxAV setAudioBitRate:5555 force:NO forFriend:1234 error:nil]).andReturn(YES);
    self.callManager.toxAV = toxAV;

    XCTAssertTrue([self.callManager setAudioBitrate:5555 forCall:call error:nil]);
    OCMVerify([toxAV setAudioBitRate:5555 force:NO forFriend:1234 error:nil]);
}

- (void)testSetVideoBitRate
{
    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = (RLMArray<OCTFriend> *)(@[friend]);

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];

    id toxAV = OCMClassMock([OCTToxAV class]);
    OCMStub([toxAV setVideoBitRate:5555 force:NO forFriend:1234 error:nil]).andReturn(YES);
    self.callManager.toxAV = toxAV;

    XCTAssertTrue([self.callManager setVideoBitrate:5555 forCall:call error:nil]);
    OCMVerify([toxAV setVideoBitRate:5555 force:NO forFriend:1234 error:nil]);

}
#pragma mark - Delegates

- (void)testReceiveCalls
{
    id delegate = OCMProtocolMock(@protocol(OCTSubmanagerCallDelegate));
    OCMStub([delegate respondsToSelector:[OCMArg anySelector]]).andReturn(YES);
    self.callManager.delegate = delegate;

    OCTCall *call = [self.callManager getOrCreateCallFromFriend:1234];

    [self.callManager toxAV:nil receiveCallAudioEnabled:YES videoEnabled:NO friendNumber:1234];
    OCMVerify([delegate callSubmanager:self.callManager receiveCall:call audioEnabled:YES videoEnabled:NO]);
}

- (void)testCallStateChanged
{
    OCTChat *chat = [OCTChat new];
    chat.uniqueIdentifier = @"test";
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = (RLMArray<OCTFriend> *)(@[friend]);

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    OCTToxAVCallState state;

    state |= OCTToxAVCallStateReceivingAudio;
    state |= OCTToxAVCallStateReceivingVideo;
    call.state = state;

    [self.callManager.calls addObject:call];

    OCTCall *otherCall = [self.callManager.calls objectAtIndex:0];
    XCTAssertEqual(state, otherCall.state);

    state |= OCTToxAVCallStateSendingAudio;
    [self.callManager toxAV:nil callStateChanged:state friendNumber:1234];

    XCTAssertEqual(state, otherCall.state);

    state |= OCTToxAVCallStateError;
    [self.callManager toxAV:nil callStateChanged:state friendNumber:1234];
    XCTAssertEqual(self.callManager.calls.count, 0);
}

- (void)testAudioBitRateChanged
{
    id delegate = OCMProtocolMock(@protocol(OCTSubmanagerCallDelegate));
    OCMStub([delegate respondsToSelector:[OCMArg anySelector]]).andReturn(YES);
    self.callManager.delegate = delegate;

    OCTChat *chat = [OCTChat new];
    chat.uniqueIdentifier = @"test";
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 123;
    chat.friends = (RLMArray<OCTFriend> *)(@[friend]);

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    [self.callManager.calls addObject:call];

    [self.callManager toxAV:nil audioBitRateChanged:999 stable:NO friendNumber:123];
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
