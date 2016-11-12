// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "OCTRealmTests.h"

#import "OCTSubmanagerChatsImpl.h"
#import "OCTRealmManager.h"
#import "OCTTox.h"
#import "OCTMessageAbstract.h"
#import "OCTMessageText.h"

@interface OCTSubmanagerChatsImplTests : OCTRealmTests

@property (strong, nonatomic) OCTSubmanagerChatsImpl *submanager;
@property (strong, nonatomic) NSNotificationCenter *notificationCenter;
@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) id tox;

@end

@implementation OCTSubmanagerChatsImplTests

- (void)setUp
{
    [super setUp];
    self.notificationCenter = [[NSNotificationCenter alloc] init];

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));
    OCMStub([self.dataSource managerGetNotificationCenter]).andReturn(self.notificationCenter);

    OCMStub([self.dataSource managerGetRealmManager]).andReturn(self.realmManager);

    self.tox = OCMClassMock([OCTTox class]);
    OCMStub([self.dataSource managerGetTox]).andReturn(self.tox);

    self.submanager = [OCTSubmanagerChatsImpl new];
    self.submanager.dataSource = self.dataSource;
    [self.submanager configure];
}

- (void)tearDown
{
    self.dataSource = nil;
    self.tox = nil;
    self.submanager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGetOrCreateChatWithFriend
{
    OCTFriend *friend = [self createFriend];

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTChat *first = [self.realmManager getOrCreateChatWithFriend:friend];
    OCTChat *second = [self.realmManager getOrCreateChatWithFriend:friend];

    XCTAssertEqualObjects(first, second);
    XCTAssertEqualObjects([first.friends firstObject], friend);
}

- (void)testRemoveMessages
{
    XCTestExpectation *expect = [self expectationWithDescription:@""];
    [self.notificationCenter addObserverForName:kOCTScheduleFileTransferCleanupNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [expect fulfill];
    }];

    NSArray *messages = [NSArray new];
    OCMExpect([self.realmManager removeMessages:messages]);

    [self.submanager removeMessages:messages];

    [self waitForExpectationsWithTimeout:0.0 handler:nil];
    OCMVerifyAll((id)self.realmManager);
}

- (void)testRemoveMessagesWithChat
{
    XCTestExpectation *expect = [self expectationWithDescription:@""];
    [self.notificationCenter addObserverForName:kOCTScheduleFileTransferCleanupNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [expect fulfill];
    }];

    OCTChat *chat = [OCTChat new];

    OCMExpect([self.realmManager removeAllMessagesInChat:chat removeChat:YES]);

    [self.submanager removeAllMessagesInChat:chat removeChat:YES];

    [self waitForExpectationsWithTimeout:0.0 handler:nil];
    OCMVerifyAll((id)self.realmManager);
}

- (void)testSendMessageToChatSuccess
{
    id message = OCMClassMock([OCTMessageAbstract class]);

    id friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(5);
    NSArray *friends = @[friend];

    id chat = OCMClassMock([OCTChat class]);
    OCMStub([chat friends]).andReturn(friends);

    OCMStub([self.tox sendMessageWithFriendNumber:5
                                             type:OCTToxMessageTypeAction
                                          message:@"text"
                                            error:[OCMArg anyObjectRef]]).andReturn(7);
    OCMExpect([self.realmManager addMessageWithText:@"text"
                                               type:OCTToxMessageTypeAction
                                               chat:chat
                                             sender:nil
                                          messageId:7]).andReturn(message);

    XCTestExpectation *expectation = [self expectationWithDescription:@""];

    [self.submanager sendMessageToChat:chat text:@"text" type:OCTToxMessageTypeAction successBlock:^(OCTMessageAbstract *theMessage) {
        OCMVerifyAll((id)self.realmManager);
        XCTAssertEqualObjects(message, theMessage);
        [expectation fulfill];

    } failureBlock:^(NSError *error) {
        XCTAssertTrue(false, @"This block shouldn't be called");
    }];

    [self waitForExpectationsWithTimeout:0.2 handler:nil];
}

- (void)testSendMessageToChatFailure
{
    id friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(5);
    NSArray *friends = @[friend];

    id chat = OCMClassMock([OCTChat class]);
    OCMStub([chat friends]).andReturn(friends);

    NSError *error2 = OCMClassMock([NSError class]);

    OCMStub([self.tox sendMessageWithFriendNumber:5
                                             type:OCTToxMessageTypeAction
                                          message:@"text"
                                            error:[OCMArg setTo:error2]]).andReturn(0);


    XCTestExpectation *expectation = [self expectationWithDescription:@""];

    [self.submanager sendMessageToChat:chat text:@"text" type:OCTToxMessageTypeAction successBlock:^(OCTMessageAbstract *theMessage) {
        XCTAssertTrue(false, @"This block shouldn't be called");

    } failureBlock:^(NSError *error) {
        OCMVerifyAll((id)self.realmManager);
        XCTAssertEqualObjects(error, error2);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:0.2 handler:nil];
}

- (void)testSetIsTyping
{
    id friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(5);
    NSArray *friends = @[friend];

    id chat = OCMClassMock([OCTChat class]);
    OCMStub([chat friends]).andReturn(friends);

    NSError *error;
    NSError *error2 = OCMClassMock([NSError class]);

    OCMExpect([self.tox setUserIsTyping:YES forFriendNumber:5 error:[OCMArg setTo:error2]]).andReturn(NO);

    XCTAssertFalse([self.submanager setIsTyping:YES inChat:chat error:&error]);

    XCTAssertEqual(error, error2);
    OCMVerifyAll(self.tox);
}

- (void)testResendUndeliveredMessages
{
    NSArray * (^createMessages)(OCTChat *, OCTToxMessageId) = ^(OCTChat *chat, OCTToxMessageId number) {
        NSMutableArray *array = [NSMutableArray new];

        for (OCTToxMessageId index = 0; index < number; index++) {
            BOOL outgoing = index % 2;
            OCTMessageAbstract *message = [self createTextMessageInChat:chat outgoing:outgoing messageId:index];
            [array addObject:message];
        }

        return [array copy];
    };

    OCTToxFriendNumber friendNumber = 1;

    OCTFriend *friend1 = [self createFriendWithFriendNumber:friendNumber++];
    OCTFriend *friend2 = [self createFriendWithFriendNumber:friendNumber++];

    OCTChat *chat1 = [self createChatWithFriend:friend1];
    OCTChat *chat2 = [self createChatWithFriend:friend2];

    NSArray *messages1 = createMessages(chat1, 10);
    NSArray *messages2 = createMessages(chat2, 2);

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:chat1];
    [self.realmManager.realm addObject:chat2];
    [self.realmManager.realm addObjects:messages1];
    [self.realmManager.realm addObjects:messages2];
    [self.realmManager.realm commitWriteTransaction];

    OCMStub([self.tox sendMessageWithFriendNumber:1 type:OCTToxMessageTypeNormal message:@"1" error:[OCMArg anyObjectRef]]).andReturn(101);
    OCMStub([self.tox sendMessageWithFriendNumber:1 type:OCTToxMessageTypeNormal message:@"3" error:[OCMArg anyObjectRef]]).andReturn(103);
    OCMStub([self.tox sendMessageWithFriendNumber:1 type:OCTToxMessageTypeNormal message:@"5" error:[OCMArg anyObjectRef]]).andReturn(105);
    OCMStub([self.tox sendMessageWithFriendNumber:1 type:OCTToxMessageTypeNormal message:@"7" error:[OCMArg anyObjectRef]]).andReturn(107);
    OCMStub([self.tox sendMessageWithFriendNumber:1 type:OCTToxMessageTypeNormal message:@"9" error:[OCMArg anyObjectRef]]).andReturn(109);

    [self.realmManager.realm beginWriteTransaction];
    friend1.connectionStatus = OCTToxConnectionStatusUDP;
    friend1.isConnected = YES;
    [self.realmManager.realm commitWriteTransaction];

    [self.notificationCenter postNotificationName:kOCTFriendConnectionStatusChangeNotification object:friend1];

#define VERIFY_MESSAGE(__array, __index, __messageId, __delivered) \
    { \
        NSString *identifier = [__array[__index] uniqueIdentifier]; \
        OCTMessageAbstract *message = [self.realmManager objectWithUniqueIdentifier:identifier class:[OCTMessageAbstract class]]; \
        XCTAssertEqual(message.messageText.messageId, __messageId); \
        XCTAssertEqual(message.messageText.isDelivered, __delivered); \
    }

    XCTestExpectation *expectation = [self expectationWithDescription:@""];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        VERIFY_MESSAGE(messages1, 0, 0, NO);
        VERIFY_MESSAGE(messages1, 1, 101, NO);
        VERIFY_MESSAGE(messages1, 2, 2, NO);
        VERIFY_MESSAGE(messages1, 3, 103, NO);
        VERIFY_MESSAGE(messages1, 4, 4, NO);
        VERIFY_MESSAGE(messages1, 5, 105, NO);
        VERIFY_MESSAGE(messages1, 6, 6, NO);
        VERIFY_MESSAGE(messages1, 7, 107, NO);
        VERIFY_MESSAGE(messages1, 8, 8, NO);
        VERIFY_MESSAGE(messages1, 9, 109, NO);

        VERIFY_MESSAGE(messages2, 0, 0, NO);
        VERIFY_MESSAGE(messages2, 1, 1, NO);

        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:0.3 handler:nil];


    // Deliver some messages, then resend all left again.

    [self.submanager tox:self.tox messageDelivered:101 friendNumber:1];
    [self.submanager tox:self.tox messageDelivered:103 friendNumber:1];
    [self.submanager tox:self.tox messageDelivered:105 friendNumber:1];

    {
        OCTMessageAbstract *message;

        [self.realmManager.realm beginWriteTransaction];

        message = messages1[7];
        message.messageText.text = @"107";
        message = messages1[9];
        message.messageText.text = @"109";

        [self.realmManager.realm commitWriteTransaction];
    }

    OCMStub([self.tox sendMessageWithFriendNumber:1 type:OCTToxMessageTypeNormal message:@"107" error:[OCMArg anyObjectRef]]).andReturn(207);
    OCMStub([self.tox sendMessageWithFriendNumber:1 type:OCTToxMessageTypeNormal message:@"109" error:[OCMArg anyObjectRef]]).andReturn(209);

    [self.notificationCenter postNotificationName:kOCTFriendConnectionStatusChangeNotification object:friend1];

    XCTestExpectation *expectation2 = [self expectationWithDescription:@""];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        VERIFY_MESSAGE(messages1, 0, 0, NO);
        VERIFY_MESSAGE(messages1, 1, 101, YES);
        VERIFY_MESSAGE(messages1, 2, 2, NO);
        VERIFY_MESSAGE(messages1, 3, 103, YES);
        VERIFY_MESSAGE(messages1, 4, 4, NO);
        VERIFY_MESSAGE(messages1, 5, 105, YES);
        VERIFY_MESSAGE(messages1, 6, 6, NO);
        VERIFY_MESSAGE(messages1, 7, 207, NO);
        VERIFY_MESSAGE(messages1, 8, 8, NO);
        VERIFY_MESSAGE(messages1, 9, 209, NO);

        VERIFY_MESSAGE(messages2, 0, 0, NO);
        VERIFY_MESSAGE(messages2, 1, 1, NO);

        [expectation2 fulfill];
    });

    [self waitForExpectationsWithTimeout:0.3 handler:nil];
}

#pragma mark -  OCTToxDelegate

- (void)testFriendMessage
{
    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 5;

    OCTChat *chat = [OCTChat new];
    [chat.friends addObject:friend];

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:chat];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager tox:nil friendMessage:@"message" type:OCTToxMessageTypeAction friendNumber:5];

    RLMResults *results = [OCTMessageAbstract allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(results.count, 1);

    OCTMessageAbstract *message = [results firstObject];
    XCTAssertEqualObjects(message.senderUniqueIdentifier, friend.uniqueIdentifier);
    XCTAssertEqualObjects(message.chatUniqueIdentifier, chat.uniqueIdentifier);
    XCTAssertNotNil(message.messageText);
    XCTAssertEqualObjects(message.messageText.text, @"message");
    XCTAssertEqual(message.messageText.type, OCTToxMessageTypeAction);
}

- (void)testMessageDelivered
{
    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 5;

    OCTChat *chat = [OCTChat new];
    [chat.friends addObject:friend];

    OCTMessageAbstract *message = [OCTMessageAbstract new];
    message.chatUniqueIdentifier = chat.uniqueIdentifier;
    message.dateInterval = [[NSDate date] timeIntervalSince1970];
    message.messageText = [OCTMessageText new];
    message.messageText.text = @"";
    message.messageText.messageId = 10;
    message.messageText.isDelivered = NO;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm addObject:chat];
    [self.realmManager.realm addObject:message];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager tox:self.tox messageDelivered:10 friendNumber:5];

    XCTAssertTrue(message.messageText.isDelivered);

    OCTMessageAbstract *anotherMessageSameId = [OCTMessageAbstract new];
    anotherMessageSameId.chatUniqueIdentifier = chat.uniqueIdentifier;
    anotherMessageSameId.dateInterval = [[NSDate date] timeIntervalSince1970];
    anotherMessageSameId.messageText = [OCTMessageText new];
    anotherMessageSameId.messageText.text = @"";
    anotherMessageSameId.messageText.messageId = 10;
    anotherMessageSameId.messageText.isDelivered = NO;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:anotherMessageSameId];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager tox:self.tox messageDelivered:10 friendNumber:5];

    XCTAssertTrue(anotherMessageSameId.messageText.isDelivered);
}

- (OCTChat *)createChatWithFriend:(OCTFriend *)friend
{
    OCTChat *chat = [OCTChat new];
    [chat.friends addObject:friend];

    return chat;
}

- (OCTMessageAbstract *)createTextMessageInChat:(OCTChat *)chat outgoing:(BOOL)outgoing messageId:(OCTToxMessageId)messageId
{
    OCTMessageAbstract *message = [OCTMessageAbstract new];
    message.chatUniqueIdentifier = chat.uniqueIdentifier;
    message.messageText = [OCTMessageText new];
    message.messageText.text = [NSString stringWithFormat:@"%d", messageId];
    message.messageText.messageId = messageId;

    if (! outgoing) {
        OCTFriend *friend = chat.friends.lastObject;
        message.senderUniqueIdentifier = friend.uniqueIdentifier;
    }

    return message;
}

@end
