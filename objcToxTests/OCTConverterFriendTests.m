//
//  OCTConverterFriendTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTConverterFriend.h"
#import "OCTFriend+Private.h"
#import "OCTDBFriend.h"

static NSString *const kPublicKey = @"publicKey";
static NSString *const kName = @"name";
static NSString *const kStatusMessage = @"kStatusMessage";
static const OCTToxUserStatus kStatus = OCTToxUserStatusAway;
static const OCTToxConnectionStatus kConnectionStatus = OCTToxConnectionStatusUDP;
static NSDate *kLastSeenOnline;
static const BOOL kIsTyping = YES;

@interface OCTConverterFriendTests : XCTestCase

@property (strong, nonatomic) OCTConverterFriend *converter;

@end

@implementation OCTConverterFriendTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.converter = [OCTConverterFriend new];

    kLastSeenOnline = [NSDate date];
}

- (void)tearDown
{
    self.converter = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testObjectClassName
{
    XCTAssertEqualObjects([self.converter objectClassName], @"OCTFriend");
}

- (void)testDBObjectClassName
{
    XCTAssertEqualObjects([self.converter dbObjectClassName], @"OCTDBFriend");
}

- (void)testObjectFromRLMObject
{
    OCTDBFriend *db = [OCTDBFriend new];
    db.friendNumber = 5;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox friendExistsWithFriendNumber:5]).andReturn(YES);
    OCMStub([tox publicKeyFromFriendNumber:5 error:[OCMArg anyObjectRef]]).andReturn(kPublicKey);
    OCMStub([tox friendNameWithFriendNumber:5 error:[OCMArg anyObjectRef]]).andReturn(kName);
    OCMStub([tox friendStatusMessageWithFriendNumber:5 error:[OCMArg anyObjectRef]]).andReturn(kStatusMessage);
    OCMStub([tox friendStatusWithFriendNumber:5 error:[OCMArg anyObjectRef]]).andReturn(kStatus);
    OCMStub([tox friendConnectionStatusWithFriendNumber:5 error:[OCMArg anyObjectRef]]).andReturn(kConnectionStatus);
    OCMStub([tox friendGetLastOnlineWithFriendNumber:5 error:[OCMArg anyObjectRef]]).andReturn(kLastSeenOnline);
    OCMStub([tox isFriendTypingWithFriendNumber:5 error:[OCMArg anyObjectRef]]).andReturn(kIsTyping);

    id dataSource = OCMProtocolMock(@protocol(OCTConverterFriendDataSource));
    OCMStub([dataSource converterFriendGetTox:self.converter]).andReturn(tox);
    self.converter.dataSource = dataSource;

    OCTFriend *friend = (OCTFriend *)[self.converter objectFromRLMObject:db];

    XCTAssertNotNil(friend);

    XCTAssertEqual(friend.friendNumber, 5);
    XCTAssertEqualObjects(friend.publicKey, kPublicKey);
    XCTAssertEqualObjects(friend.name, kName);
    XCTAssertEqualObjects(friend.statusMessage, kStatusMessage);
    XCTAssertEqual(friend.status, kStatus);
    XCTAssertEqual(friend.connectionStatus, kConnectionStatus);
    XCTAssertEqualObjects(friend.lastSeenOnline, kLastSeenOnline);
    XCTAssertEqual(friend.isTyping, kIsTyping);
}

- (void)testRlmSortDescriptorFromDescriptor
{
    OCTSortDescriptor *friendNumber = [OCTSortDescriptor sortDescriptorWithProperty:@"friendNumber" ascending:YES];
    OCTSortDescriptor *name = [OCTSortDescriptor sortDescriptorWithProperty:@"name" ascending:YES];

    RLMSortDescriptor *rlm1 = [self.converter rlmSortDescriptorFromDescriptor:friendNumber];
    RLMSortDescriptor *rlm2 = [self.converter rlmSortDescriptorFromDescriptor:name];

    XCTAssertEqualObjects(friendNumber.property, rlm1.property);
    XCTAssertEqual(friendNumber.ascending, rlm1.ascending);
    XCTAssertNil(rlm2);
}

@end
