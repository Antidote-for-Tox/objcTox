//
//  OCTConverterChatTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTConverterChat.h"
#import "OCTChat+Private.h"
#import "OCTMessageAbstract+Private.h"
#import "OCTDBChat.h"

@interface OCTConverterChatTests : XCTestCase

@property (strong, nonatomic) OCTConverterChat *converter;
;

@end

@implementation OCTConverterChatTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.converter = [OCTConverterChat new];
}

- (void)tearDown
{
    self.converter = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testObjectClassName
{
    XCTAssertEqualObjects([self.converter objectClassName], @"OCTChat");
}

- (void)testDBObjectClassName
{
    XCTAssertEqualObjects([self.converter dbObjectClassName], @"OCTDBChat");
}

- (void)testObjectFromRLMObject
{
    OCTDBFriend *dbFriend0 = [OCTDBFriend new];
    OCTDBFriend *dbFriend1 = [OCTDBFriend new];
    OCTDBMessageAbstract *dbLastMessage = [OCTDBMessageAbstract new];

    id friend0 = OCMClassMock([OCTFriend class]);
    id friend1 = OCMClassMock([OCTFriend class]);
    id lastMessage = OCMClassMock([OCTMessageAbstract class]);

    OCTDBChat *db = [OCTDBChat new];
    db.uniqueIdentifier = @"identifier";
    db.friends = (RLMArray<OCTDBFriend> *) @[ dbFriend0, dbFriend1 ];
    db.lastMessage = dbLastMessage;
    db.enteredText = @"text";
    db.lastReadDateInterval = 100;

    id delegate = OCMProtocolMock(@protocol(OCTConverterChatDelegate));
    OCMStub([delegate converterChat:self.converter updateDBChatWithBlock:[OCMArg checkWithBlock:^BOOL (id obj) {
        XCTAssertNotNil(obj);

        void (^updateBlock)() = obj;
        updateBlock();
        return YES;
    }]]);

    id converterMessage = OCMClassMock([OCTConverterMessage class]);
    OCMStub([converterMessage objectFromRLMObjectWithoutChat:dbLastMessage]).andReturn(lastMessage);

    id converterFriend = OCMClassMock([OCTConverterFriend class]);
    OCMStub([converterFriend objectFromRLMObject:dbFriend0]).andReturn(friend0);
    OCMStub([converterFriend objectFromRLMObject:dbFriend1]).andReturn(friend1);

    self.converter.delegate = delegate;
    self.converter.converterMessage = converterMessage;
    self.converter.converterFriend = converterFriend;

    OCTChat *chat = (OCTChat *)[self.converter objectFromRLMObject:db];

    XCTAssertNotNil(chat);
    XCTAssertEqual(chat.uniqueIdentifier, db.uniqueIdentifier);
    XCTAssertEqual(chat.friends[0], friend0);
    XCTAssertEqual(chat.friends[1], friend1);
    XCTAssertEqual(chat.lastMessage, lastMessage);
    OCMVerify([lastMessage setChat:chat]);
    XCTAssertEqualObjects(chat.enteredText, db.enteredText);
    XCTAssertEqualObjects(chat.lastReadDate, [NSDate dateWithTimeIntervalSince1970:db.lastReadDateInterval]);

    chat.enteredText = @"new message";
    XCTAssertEqualObjects(chat.enteredText, db.enteredText);

    chat.lastReadDate = [NSDate dateWithTimeIntervalSince1970:300];
    XCTAssertEqualObjects(chat.lastReadDate, [NSDate dateWithTimeIntervalSince1970:db.lastReadDateInterval]);
}

- (void)testRlmSortDescriptorFromDescriptor
{
    OCTSortDescriptor *lastMessage = [OCTSortDescriptor sortDescriptorWithProperty:@"lastMessage" ascending:YES];
    OCTSortDescriptor *enteredText = [OCTSortDescriptor sortDescriptorWithProperty:@"enteredText" ascending:YES];
    OCTSortDescriptor *lastReadDate = [OCTSortDescriptor sortDescriptorWithProperty:@"lastReadDate" ascending:YES];

    RLMSortDescriptor *rlm1 = [self.converter rlmSortDescriptorFromDescriptor:lastMessage];
    RLMSortDescriptor *rlm2 = [self.converter rlmSortDescriptorFromDescriptor:enteredText];
    RLMSortDescriptor *rlm3 = [self.converter rlmSortDescriptorFromDescriptor:lastReadDate];

    XCTAssertEqualObjects(lastMessage.property, rlm1.property);
    XCTAssertEqual(lastMessage.ascending, rlm1.ascending);
    XCTAssertEqualObjects(enteredText.property, rlm2.property);
    XCTAssertEqual(enteredText.ascending, rlm2.ascending);
    XCTAssertEqualObjects(@"lastReadDateInterval", rlm3.property);
    XCTAssertEqual(enteredText.ascending, rlm3.ascending);
}

@end
