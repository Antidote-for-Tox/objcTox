//
//  OCTSubmanagerObjectsTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTSubmanagerObjects+Private.h"
#import "OCTRealmManager.h"
#import "OCTFriend.h"
#import "OCTFriendRequest.h"
#import "OCTChat.h"
#import "OCTMessageAbstract.h"
#import "OCTSettingsStorageObject.h"

@interface OCTSubmanagerObjectsTests : XCTestCase

@property (strong, nonatomic) OCTSubmanagerObjects *submanager;
@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) id realmManager;

@end

@implementation OCTSubmanagerObjectsTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));

    self.realmManager = OCMClassMock([OCTRealmManager class]);
    OCMStub([self.dataSource managerGetRealmManager]).andReturn(self.realmManager);

    self.submanager = [OCTSubmanagerObjects new];
    self.submanager.dataSource = self.dataSource;
}

- (void)tearDown
{
    self.dataSource = nil;
    self.realmManager = nil;
    self.submanager = nil;

    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFetchRequestByType
{
    id predicate = OCMClassMock([NSPredicate class]);

    id results1 = OCMClassMock([RLMResults class]);
    id results2 = OCMClassMock([RLMResults class]);
    id results3 = OCMClassMock([RLMResults class]);
    id results4 = OCMClassMock([RLMResults class]);

    OCMStub([self.realmManager objectsWithClass:[OCTFriend class]
                                      predicate:predicate]).andReturn(results1);
    OCMStub([self.realmManager objectsWithClass:[OCTFriendRequest class]
                                      predicate:predicate]).andReturn(results2);
    OCMStub([self.realmManager objectsWithClass:[OCTChat class]
                                      predicate:predicate]).andReturn(results3);
    OCMStub([self.realmManager objectsWithClass:[OCTMessageAbstract class]
                                      predicate:predicate]).andReturn(results4);

    XCTAssertEqual(results1, [self.submanager objectsForType:OCTFetchRequestTypeFriend
                                                   predicate:predicate]);
    XCTAssertEqual(results2, [self.submanager objectsForType:OCTFetchRequestTypeFriendRequest
                                                   predicate:predicate]);
    XCTAssertEqual(results3, [self.submanager objectsForType:OCTFetchRequestTypeChat
                                                   predicate:predicate]);
    XCTAssertEqual(results4, [self.submanager objectsForType:OCTFetchRequestTypeMessageAbstract
                                                   predicate:predicate]);
}

- (void)testGenericSettingsData
{
    NSData *data = [@"some string" dataUsingEncoding:NSUTF8StringEncoding];

    id settingsStorage = OCMClassMock([OCTSettingsStorageObject class]);
    OCMStub([settingsStorage genericSettingsData]).andReturn(data);
    OCMExpect([settingsStorage setGenericSettingsData:data]);

    OCMStub([self.realmManager settingsStorage]).andReturn(settingsStorage);

    XCTAssertEqual(self.submanager.genericSettingsData, data);
    self.submanager.genericSettingsData = data;

    OCMVerify(settingsStorage);
}

- (void)testObjectWithUniqueIdentifier
{
    NSString *identifier = @"identifier";

    id object1 = OCMClassMock([OCTObject class]);
    id object2 = OCMClassMock([OCTObject class]);
    id object3 = OCMClassMock([OCTObject class]);
    id object4 = OCMClassMock([OCTObject class]);

    OCMStub([self.realmManager objectWithUniqueIdentifier:identifier class:[OCTFriend class]]).andReturn(object1);
    OCMStub([self.realmManager objectWithUniqueIdentifier:identifier class:[OCTFriendRequest class]]).andReturn(object2);
    OCMStub([self.realmManager objectWithUniqueIdentifier:identifier class:[OCTChat class]]).andReturn(object3);
    OCMStub([self.realmManager objectWithUniqueIdentifier:identifier class:[OCTMessageAbstract class]]).andReturn(object4);

    XCTAssertEqual(object1, [self.submanager objectWithUniqueIdentifier:identifier forType:OCTFetchRequestTypeFriend]);
    XCTAssertEqual(object2, [self.submanager objectWithUniqueIdentifier:identifier forType:OCTFetchRequestTypeFriendRequest]);
    XCTAssertEqual(object3, [self.submanager objectWithUniqueIdentifier:identifier forType:OCTFetchRequestTypeChat]);
    XCTAssertEqual(object4, [self.submanager objectWithUniqueIdentifier:identifier forType:OCTFetchRequestTypeMessageAbstract]);
}

- (void)testChangeFriendNickname
{
    OCTFriend *friend = [OCTFriend new];

    OCMStub([self.realmManager updateObject:friend withBlock:[OCMArg checkWithBlock:^BOOL (id obj) {
        void (^block)(id) = obj;
        block(friend);
        return YES;
    }]]);

    [self.submanager changeFriend:friend nickname:@"new"];

    XCTAssertEqualObjects(friend.nickname, @"new");
}

- (void)testChangeFriendNicknameEmpty1
{
    OCTFriend *friend = [OCTFriend new];
    friend.nickname = @"nickname";
    friend.name = @"name";
    friend.publicKey = @"public";

    OCMStub([self.realmManager updateObject:friend withBlock:[OCMArg checkWithBlock:^BOOL (id obj) {
        void (^block)(id) = obj;
        block(friend);
        return YES;
    }]]);

    [self.submanager changeFriend:friend nickname:@""];

    XCTAssertEqualObjects(friend.nickname, @"name");
}

- (void)testChangeFriendNicknameEmpty2
{
    OCTFriend *friend = [OCTFriend new];
    friend.nickname = @"nickname";
    friend.name = @"";
    friend.publicKey = @"public";

    OCMStub([self.realmManager updateObject:friend withBlock:[OCMArg checkWithBlock:^BOOL (id obj) {
        void (^block)(id) = obj;
        block(friend);
        return YES;
    }]]);

    [self.submanager changeFriend:friend nickname:@""];

    XCTAssertEqualObjects(friend.nickname, @"public");
}

- (void)testChangeChatEnteredText
{
    OCTChat *chat = [OCTChat new];

    OCMStub([self.realmManager updateObject:chat withBlock:[OCMArg checkWithBlock:^BOOL (id obj) {
        void (^block)(id) = obj;
        block(chat);
        return YES;
    }]]);

    [self.submanager changeChat:chat enteredText:@"text"];

    XCTAssertEqualObjects(chat.enteredText, @"text");
}

- (void)testChangeChatEnteredLastReadDateInterval
{
    OCTChat *chat = [OCTChat new];

    OCMStub([self.realmManager updateObject:chat withBlock:[OCMArg checkWithBlock:^BOOL (id obj) {
        void (^block)(id) = obj;
        block(chat);
        return YES;
    }]]);

    [self.submanager changeChat:chat lastReadDateInterval:17];

    XCTAssertEqual(chat.lastReadDateInterval, 17);
}

@end
