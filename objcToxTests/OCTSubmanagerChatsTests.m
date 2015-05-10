//
//  OCTSubmanagerChatsTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 10.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import <Realm/Realm.h>

#import "OCTSubmanagerChat+Private.h"
#import "OCTDBManager.h"
#import "OCTConverterChat.h"
#import "OCTFriend+Private.h"

@interface OCTArray(Tests)
@property (strong, nonatomic) RLMResults *results;
@property (strong, nonatomic) id<OCTConverterProtocol> converter;
@end

@interface OCTSubmanagerChatsTests : XCTestCase

@property (strong, nonatomic) OCTSubmanagerChat *submanager;
@property (strong, nonatomic) id dataSource;

@end

@implementation OCTSubmanagerChatsTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));

    self.submanager = [OCTSubmanagerChat new];
    self.submanager.dataSource = self.dataSource;
}

- (void)tearDown
{
    self.dataSource = nil;
    self.submanager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAllChats
{
    id results = OCMClassMock([RLMResults class]);

    id dbManager = OCMClassMock([OCTDBManager class]);
    OCMStub([dbManager allChats]).andReturn(results);

    OCMStub([self.dataSource managerGetDBManager]).andReturn(dbManager);

    OCTArray *array = [self.submanager allChats];

    XCTAssertEqualObjects(results, array.results);
    XCTAssertTrue([array.converter isKindOfClass:[OCTConverterChat class]]);

    OCTConverterChat *converter = (OCTConverterChat *)array.converter;
    XCTAssertNotNil(converter.converterFriend);
    XCTAssertNotNil(converter.converterMessage);
    XCTAssertNotNil(converter.converterMessage.converterFriend);
}

- (void)testGetOrCreateChatWithFriend
{
    OCTDBChat *db = [OCTDBChat new];
    db.enteredText = @"text";
    db.lastReadDateInterval = 70;

    id dbManager = OCMClassMock([OCTDBManager class]);
    OCMStub([dbManager getOrCreateChatWithFriendNumber:7]).andReturn(db);

    OCMStub([self.dataSource managerGetDBManager]).andReturn(dbManager);

    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 7;

    OCTChat *chat = [self.submanager getOrCreateChatWithFriend:friend];

    XCTAssertEqualObjects(chat.enteredText, @"text");
    XCTAssertEqual([chat.lastReadDate timeIntervalSince1970], 70);
}

- (void)testSetIsTyping
{
    id tox = OCMClassMock([OCTTox class]);
    OCMStub([self.dataSource managerGetTox]).andReturn(tox);

    OCTFriend *friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(7);

    NSArray *array = @[ friend ];

    id chat = OCMClassMock([OCTChat class]);
    OCMStub([chat friends]).andReturn(array);

    NSError *error = nil;
    NSError *error2 = OCMClassMock([NSError class]);

    OCMExpect([tox setUserIsTyping:YES forFriendNumber:7 error:[OCMArg setTo:error2]]);

    [self.submanager setIsTyping:YES inChat:chat error:&error];

    OCMVerifyAll(tox);
    XCTAssertEqual(error, error2);
}

@end
