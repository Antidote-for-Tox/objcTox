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

#import "OCTSubmanagerChats+Private.h"
#import "OCTDBManager.h"
#import "OCTConverterChat.h"
#import "OCTFriend+Private.h"
#import "OCTChat+Private.h"

@interface OCTArray(Tests)
@property (strong, nonatomic) RLMResults *results;
@property (strong, nonatomic) id<OCTConverterProtocol> converter;
@end

@interface OCTSubmanagerChatsTests : XCTestCase

@property (strong, nonatomic) OCTSubmanagerChats *submanager;
@property (strong, nonatomic) id dataSource;

@end

@implementation OCTSubmanagerChatsTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));

    self.submanager = [OCTSubmanagerChats new];
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
    id db = OCMClassMock([OCTDBChat class]);
    OCMStub([db enteredText]).andReturn(@"text");
    OCMStub([db lastReadDateInterval]).andReturn(70);

    id dbManager = OCMClassMock([OCTDBManager class]);
    OCMStub([dbManager getOrCreateChatWithFriendNumber:7]).andReturn(db);

    OCMStub([self.dataSource managerGetDBManager]).andReturn(dbManager);

    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 7;

    OCTChat *chat = [self.submanager getOrCreateChatWithFriend:friend];

    XCTAssertEqualObjects(chat.enteredText, @"text");
    XCTAssertEqual([chat.lastReadDate timeIntervalSince1970], 70);
}

- (void)testAllMessagesInChat
{
    id results = OCMClassMock([RLMResults class]);
    id dbChat = OCMClassMock([OCTDBChat class]);

    id dbManager = OCMClassMock([OCTDBManager class]);
    OCMStub([dbManager chatWithUniqueIdentifier:@"identifier"]).andReturn(dbChat);
    OCMStub([dbManager allMessagesInChat:dbChat]).andReturn(results);

    OCMStub([self.dataSource managerGetDBManager]).andReturn(dbManager);

    OCTChat *chat = [OCTChat new];
    chat.uniqueIdentifier = @"identifier";

    OCTArray *array = [self.submanager allMessagesInChat:chat];

    XCTAssertEqualObjects(results, array.results);
    XCTAssertTrue([array.converter isKindOfClass:[OCTConverterMessage class]]);

    OCTConverterChat *converter = (OCTConverterChat *)array.converter;
    XCTAssertNotNil(converter.converterFriend);
}

- (void)testSendMessage
{
    id tox = OCMClassMock([OCTTox class]);
    OCMStub([self.dataSource managerGetTox]).andReturn(tox);

    OCTFriend *friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(7);

    NSArray *array = @[ friend ];

    id chat = OCMClassMock([OCTChat class]);
    OCMStub([chat friends]).andReturn(array);

    id dbMessage = OCMClassMock([OCTDBMessageAbstract class]);

    id dbManager = OCMClassMock([OCTDBManager class]);
    OCMStub([self.dataSource managerGetDBManager]).andReturn(dbManager);
    OCMStub([dbManager getOrCreateChatWithFriendNumber:7]).andReturn(chat);
    OCMExpect([dbManager addMessageWithText:@"text"
                                       type:OCTToxMessageTypeAction
                                       chat:chat
                                     sender:nil
                                  messageId:10]).andReturn(dbMessage);

    NSError *error = nil;
    NSError *error2 = OCMClassMock([NSError class]);

    OCMExpect([tox sendMessageWithFriendNumber:7
                                          type:OCTToxMessageTypeAction
                                       message:@"text"
                                         error:[OCMArg setTo:error2]]).andReturn(10);

    [self.submanager sendMessageToChat:chat text:@"text" type:OCTToxMessageTypeAction error:&error];

    OCMVerifyAll(tox);
    OCMVerifyAll(dbManager);
    XCTAssertEqual(error, error2);
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

#pragma mark -  OCTToxDelegate

- (void)testFriendMessage
{
    id friend = OCMClassMock([OCTDBFriend class]);
    id chat = OCMClassMock([OCTDBChat class]);

    id dbManager = OCMClassMock([OCTDBManager class]);
    OCMStub([dbManager getOrCreateFriendWithFriendNumber:7]).andReturn(friend);
    OCMStub([dbManager getOrCreateChatWithFriendNumber:7]).andReturn(chat);

    OCMStub([self.dataSource managerGetDBManager]).andReturn(dbManager);

    [self.submanager tox:nil friendMessage:@"message" type:OCTToxMessageTypeAction friendNumber:7];

    OCMVerify([dbManager addMessageWithText:@"message" type:OCTToxMessageTypeAction chat:chat sender:friend]);
}

- (void)testMessageDelivered
{
    OCTDBMessageAbstract *message = [OCTDBMessageAbstract new];
    message.textMessage = [OCTDBMessageText new];
    message.textMessage.isDelivered = NO;

    id chat = OCMClassMock([OCTDBChat class]);

    id dbManager = OCMClassMock([OCTDBManager class]);
    OCMStub([self.dataSource managerGetDBManager]).andReturn(dbManager);

    OCMStub([dbManager getOrCreateChatWithFriendNumber:7]).andReturn(chat);
    OCMStub([dbManager textMessageInChat:chat withMessageId:10]).andReturn(message);
    OCMStub([dbManager updateDBObjectInBlock:[OCMArg checkWithBlock:^BOOL (id obj) {
        XCTAssertNotNil(obj);

        void (^updateBlock)() = obj;
        updateBlock();
        return YES;
    }]]);

    [self.submanager tox:nil messageDelivered:10 friendNumber:7];

    XCTAssertTrue(message.textMessage.isDelivered);
}

@end
