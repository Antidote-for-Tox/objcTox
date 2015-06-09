//
//  OCTConverterCallTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCTConverterCall.h"
#import "OCTCall.h"
#import "OCTDBCall.h"
#import "OCTChat+Private.h"
#import "OCTFriend+Private.h"
#import <OCMock/OCMock.h>

@interface OCTConverterCallTests : XCTestCase

@property (strong, nonatomic)  OCTConverterCall *callConverter;

@end

@implementation OCTConverterCallTests

- (void)setUp
{
    [super setUp];
    self.callConverter = [OCTConverterCall new];

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    self.callConverter = nil;

    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testConvertFromRlmObject
{
    id mockedChatConverter = OCMClassMock([OCTConverterCall class]);
    self.callConverter.converterChat = mockedChatConverter;
    OCTChat *chat = [OCTChat new];
    id friend1 = OCMClassMock([OCTFriend class]);
    id friend2 = OCMClassMock([OCTFriend class]);
    chat.friends = @[friend1, friend2];
    chat.uniqueIdentifier = @"myUniqueIdentifier";

    OCTDBChat *dbChat = [OCTDBChat new];
    OCMStub([mockedChatConverter objectFromRLMObject:dbChat]).andReturn(chat);

    OCTDBCall *dbCall = [OCTDBCall new];
    dbCall.chat = dbChat;

    OCTCall *call = [self.callConverter objectFromRLMObject:dbCall];

    XCTAssertNotNil(call);
    XCTAssertEqual(2, call.friends.count);
    XCTAssertEqualObjects(friend1, call.friends.firstObject);
    XCTAssertEqualObjects(friend2, call.friends[1]);
    XCTAssertEqualObjects(chat.uniqueIdentifier, call.chatSession.uniqueIdentifier);
}
@end
