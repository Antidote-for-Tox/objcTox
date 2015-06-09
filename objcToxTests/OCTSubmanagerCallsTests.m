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
#import "OCTFriend+Private.h"
#import "OCTChat+Private.h"
#import <OCMock/OCMock.h>

@interface OCTSubmanagerCalls (Tests)

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;
@property (strong, nonatomic) NSMutableSet *mutableCalls;

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
    XCTAssertNotNil(self.callManager.calls);
    XCTAssertNotNil(self.callManager.audioEngine);
    XCTAssertEqual(0, self.callManager.calls.count);
}

- (void)testCallToChat
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;
    [OCMExpect([toxAV callFriendNumber:1234 audioBitRate:0 videoBitRate:kOCTToxAVVideoBitRateDisable error:nil]) ignoringNonObjectArgs];

    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = @[friend];

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    OCTCall *callResult = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO];

    XCTAssertEqualObjects(call, callResult);
    XCTAssertEqual(self.callManager.mutableCalls.count, 1);

    OCMVerifyAll(toxAV);
}

- (void)testEndCall
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    OCMExpect([toxAV sendCallControl:OCTToxAVCallControlCancel toFriendNumber:1234 error:[OCMArg anyObjectRef]]);
    self.callManager.toxAV = toxAV;

    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = @[friend];

    OCTCall *call = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO];

    XCTAssertEqual(self.callManager.mutableCalls.count, 1);

    [self.callManager endCall:call error:nil];

    XCTAssertEqual(0, self.callManager.mutableCalls.count);
    OCMVerifyAll(toxAV);
}



@end
