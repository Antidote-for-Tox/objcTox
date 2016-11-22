// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "OCTRealmTests.h"
#import "OCTSubmanagerFriendsImpl.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTTox.h"
#import "OCTFriendRequest.h"

static const OCTToxFriendNumber kFriendNumber = 5;
static NSString *const kPublicKey = @"kPublicKey";
static NSString *const kName = @"kName";
static NSString *const kStatusMessage = @"kStatusMessage";
static const OCTToxUserStatus kStatus = OCTToxUserStatusAway;
static const OCTToxConnectionStatus kConnectionStatus = OCTToxConnectionStatusUDP;
static const BOOL kIsTyping = YES;
static NSDate *sLastSeenOnline;
static NSString *const kMessage = @"kMessage";

@interface OCTSubmanagerFriendsImplTests : OCTRealmTests

@property (strong, nonatomic) OCTSubmanagerFriendsImpl *submanager;
@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) id tox;

@end

@implementation OCTSubmanagerFriendsImplTests

- (void)setUp
{
    [super setUp];

    sLastSeenOnline = [NSDate date];

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));

    OCMStub([self.dataSource managerGetRealmManager]).andReturn(self.realmManager);

    self.tox = OCMClassMock([OCTTox class]);
    OCMStub([self.dataSource managerGetTox]).andReturn(self.tox);

    self.submanager = [OCTSubmanagerFriendsImpl new];
    self.submanager.dataSource = self.dataSource;
}

- (void)tearDown
{
    self.dataSource = nil;
    self.tox = nil;
    self.submanager = nil;

    [super tearDown];
}

- (void)testConfigure
{
    OCTFriend *friend = [self createFriendWithFriendNumber:5];
    friend.status = OCTToxUserStatusBusy;
    friend.isConnected = YES;
    friend.connectionStatus = OCTToxConnectionStatusUDP;
    friend.isTyping = YES;

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:5 error:[OCMArg anyObjectRef]]).andReturn(publicKey);

    NSArray *array = @[@(5)];
    OCMStub([self.tox friendsArray]).andReturn(array);

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager configure];

    XCTAssertEqual(friend.status, OCTToxUserStatusNone);
    XCTAssertFalse(friend.isConnected);
    XCTAssertEqual(friend.connectionStatus, OCTToxConnectionStatusNone);
    XCTAssertFalse(friend.isTyping);
}

- (void)testConfigure2
{
    OCTFriend *friend = [self createFriendWithFriendNumber:99];
    // This one should be removed.
    OCTFriend *unboundedFriend = [self createFriendWithFriendNumber:33];

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm addObject:unboundedFriend];
    [self.realmManager.realm commitWriteTransaction];

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:99 error:[OCMArg anyObjectRef]]).andReturn(publicKey);

    NSArray *array = @[@(99), @(kFriendNumber)];
    OCMStub([self.tox friendsArray]).andReturn(array);
    [self stubFriendMethodsInTox];

    [self.submanager configure];

    RLMResults *objects = [OCTFriend allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(objects.count, 2);

    OCTFriend *first = objects[0];
    OCTFriend *second = objects[1];

    XCTAssertEqualObjects(friend, first);
    [self verifyFriend:second];
}

#pragma mark -  Public

- (void)testSendFriendRequestSuccess
{
    [self stubFriendMethodsInTox];

    OCMExpect([self.tox addFriendWithAddress:kPublicKey message:@"message" error:nil]).andReturn(kFriendNumber);

    BOOL result = [self.submanager sendFriendRequestToAddress:kPublicKey message:@"message" error:nil];

    XCTAssertTrue(result);
    OCMVerify([self.dataSource managerSaveTox]);
    OCMVerifyAll(self.tox);

    RLMResults *objects = [OCTFriend allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(objects.count, 1);

    OCTFriend *friend = [objects firstObject];

    [self verifyFriend:friend];
}

- (void)testSendFriendRequestFailure
{
    NSError *error;
    NSError *error2 = [NSError new];

    [[self.dataSource reject] managerSaveTox];
    OCMExpect([self.tox addFriendWithAddress:kPublicKey message:@"message" error:[OCMArg setTo:error2]]).andReturn(kOCTToxFriendNumberFailure);

    BOOL result = [self.submanager sendFriendRequestToAddress:kPublicKey message:@"message" error:&error];

    XCTAssertFalse(result);
    XCTAssertEqualObjects(error, error2);
}

- (void)testApproveFriendRequestSuccess
{
    [self stubFriendMethodsInTox];

    OCTFriendRequest *friendRequest = [OCTFriendRequest new];
    friendRequest.publicKey = kPublicKey;
    friendRequest.message = @"message";

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friendRequest];
    [self.realmManager.realm commitWriteTransaction];

    OCMExpect([self.tox addFriendWithNoRequestWithPublicKey:kPublicKey error:nil]).andReturn(kFriendNumber);

    BOOL result = [self.submanager approveFriendRequest:friendRequest error:nil];

    XCTAssertTrue(result);
    OCMVerify([self.dataSource managerSaveTox]);
    OCMVerifyAll(self.tox);

    RLMResults *objects = [OCTFriendRequest allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(objects.count, 0);

    objects = [OCTFriend allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(objects.count, 1);

    OCTFriend *friend = [objects firstObject];

    [self verifyFriend:friend];
}

- (void)testApproveFriendRequestFailure
{
    OCTFriendRequest *friendRequest = [OCTFriendRequest new];
    friendRequest.publicKey = kPublicKey;
    friendRequest.message = @"message";

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friendRequest];
    [self.realmManager.realm commitWriteTransaction];

    NSError *error;
    NSError *error2 = [NSError new];

    [[self.dataSource reject] managerSaveTox];
    OCMExpect([self.tox addFriendWithNoRequestWithPublicKey:kPublicKey error:[OCMArg setTo:error2]]).andReturn(kOCTToxFriendNumberFailure);

    BOOL result = [self.submanager approveFriendRequest:friendRequest error:&error];

    XCTAssertFalse(result);
    XCTAssertEqualObjects(error, error2);

    RLMResults *objects = [OCTFriendRequest allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(objects.count, 1);

    XCTAssertEqualObjects(friendRequest, [objects firstObject]);
}

- (void)testRemoveFriendRequest
{
    OCTFriendRequest *friendRequest = [OCTFriendRequest new];
    friendRequest.publicKey = kPublicKey;
    friendRequest.message = @"message";

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friendRequest];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager removeFriendRequest:friendRequest];

    RLMResults *objects = [OCTFriendRequest allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(objects.count, 0);
}

- (void)testRemoveFriendSuccess
{
    OCTFriend *friend = [self createFriendWithFriendNumber:kFriendNumber];

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(publicKey);

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCMExpect([self.tox deleteFriendWithFriendNumber:kFriendNumber error:nil]).andReturn(YES);

    BOOL result = [self.submanager removeFriend:friend error:nil];

    XCTAssertTrue(result);
    OCMVerify([self.dataSource managerSaveTox]);

    RLMResults *objects = [OCTFriend allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(objects.count, 0);
}

- (void)testRemoveFriendFailure
{
    OCTFriend *friend = [self createFriendWithFriendNumber:kFriendNumber];

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(publicKey);

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    NSError *error;
    NSError *error2 = [NSError new];

    [[self.dataSource reject] managerSaveTox];
    OCMExpect([self.tox deleteFriendWithFriendNumber:kFriendNumber error:[OCMArg setTo:error2]]).andReturn(NO);

    BOOL result = [self.submanager removeFriend:friend error:&error];

    XCTAssertFalse(result);

    RLMResults *objects = [OCTFriend allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(objects.count, 1);
    XCTAssertEqualObjects([objects firstObject], friend);
}

#pragma mark -  OCTToxDelegate

- (void)testFriendRequestWithMessage
{
    [self.submanager tox:self.tox friendRequestWithMessage:kMessage publicKey:kPublicKey];

    RLMResults *objects = [OCTFriendRequest allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(objects.count, 1);

    OCTFriendRequest *request = [objects firstObject];
    XCTAssertEqualObjects(request.publicKey, kPublicKey);
    XCTAssertEqualObjects(request.message, kMessage);
    XCTAssertTrue(([[NSDate date] timeIntervalSince1970] - request.dateInterval) < 0.1);
}

- (void)testFriendRequestWithMessageDuplicate
{
    // trying to add same friend request twice
    [self.submanager tox:self.tox friendRequestWithMessage:kMessage publicKey:kPublicKey];
    [self.submanager tox:self.tox friendRequestWithMessage:kMessage publicKey:kPublicKey];

    RLMResults *objects = [OCTFriendRequest allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(objects.count, 1);

    OCTFriendRequest *request = [objects firstObject];
    XCTAssertEqualObjects(request.publicKey, kPublicKey);
    XCTAssertEqualObjects(request.message, kMessage);
    XCTAssertTrue(([[NSDate date] timeIntervalSince1970] - request.dateInterval) < 0.1);
}

- (void)testFriendRequestWithMessageFriendExists
{
    OCTFriend *friend = [self createFriendWithFriendNumber:kFriendNumber];
    friend.publicKey = kPublicKey;
    friend.status = OCTToxUserStatusBusy;
    friend.isConnected = YES;
    friend.connectionStatus = OCTToxConnectionStatusUDP;
    friend.isTyping = YES;

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(publicKey);

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager tox:self.tox friendRequestWithMessage:kMessage publicKey:kPublicKey];

    RLMResults *objects = [OCTFriendRequest allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(objects.count, 0);
}

- (void)testFriendNameUpdate
{
    OCTFriend *friend = [self createFriendWithFriendNumber:kFriendNumber];
    friend.publicKey = kPublicKey;
    friend.nickname = kPublicKey;

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(publicKey);

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager tox:self.tox friendNameUpdate:@"" friendNumber:kFriendNumber];
    XCTAssertEqualObjects(friend.name, @"");
    XCTAssertEqualObjects(friend.nickname, kPublicKey);

    [self.submanager tox:self.tox friendNameUpdate:kName friendNumber:kFriendNumber];
    XCTAssertEqualObjects(friend.name, kName);
    XCTAssertEqualObjects(friend.nickname, kName);
}

- (void)testStatusMessageUpdate
{
    OCTFriend *friend = [self createFriendWithFriendNumber:kFriendNumber];

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(publicKey);

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager tox:self.tox friendStatusMessageUpdate:kStatusMessage friendNumber:kFriendNumber];
    XCTAssertEqualObjects(friend.statusMessage, kStatusMessage);
}

- (void)testStatusUpdate
{
    OCTFriend *friend = [self createFriendWithFriendNumber:kFriendNumber];

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(publicKey);

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager tox:self.tox friendStatusUpdate:kStatus friendNumber:kFriendNumber];
    XCTAssertEqual(friend.status, kStatus);
}

- (void)testLastSeenDate
{
    OCTFriend *friend = [self createFriendWithFriendNumber:kFriendNumber];
    friend.lastSeenOnlineInterval = 0;

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(publicKey);

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    XCTAssertNil([friend lastSeenOnline]);

    [self.submanager tox:self.tox friendConnectionStatusChanged:OCTToxConnectionStatusTCP friendNumber:kFriendNumber];

    XCTAssertNil([friend lastSeenOnline]);
    XCTAssertEqual(friend.lastSeenOnlineInterval, 0);

    [self stubFriendMethodsInTox];
    [self.submanager tox:self.tox friendConnectionStatusChanged:OCTToxConnectionStatusNone friendNumber:kFriendNumber];
    XCTAssertEqual(friend.lastSeenOnlineInterval, [sLastSeenOnline timeIntervalSince1970]);
}

- (void)testIsTypingUpdate
{
    OCTFriend *friend = [self createFriendWithFriendNumber:kFriendNumber];

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(publicKey);

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager tox:self.tox friendIsTypingUpdate:kIsTyping friendNumber:kFriendNumber];
    XCTAssertEqual(friend.isTyping, kIsTyping);
}

- (void)testFriendConnectionStatusChanged
{
    OCTFriend *friend = [self createFriendWithFriendNumber:kFriendNumber];

    NSString *publicKey = friend.publicKey;
    OCMStub([self.tox publicKeyFromFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(publicKey);

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager tox:self.tox friendConnectionStatusChanged:OCTToxConnectionStatusUDP friendNumber:kFriendNumber];
    XCTAssertEqual(friend.connectionStatus, OCTToxConnectionStatusUDP);
    XCTAssertTrue(friend.isConnected);

    [self.submanager tox:self.tox friendConnectionStatusChanged:OCTToxConnectionStatusNone friendNumber:kFriendNumber];
    XCTAssertEqual(friend.connectionStatus, OCTToxConnectionStatusNone);
    XCTAssertFalse(friend.isConnected);

    [self.submanager tox:self.tox friendConnectionStatusChanged:OCTToxConnectionStatusTCP friendNumber:kFriendNumber];
    XCTAssertEqual(friend.connectionStatus, OCTToxConnectionStatusTCP);
    XCTAssertTrue(friend.isConnected);

    NSNotificationCenter *center = [[NSNotificationCenter alloc] init];
    OCMStub([self.dataSource managerGetNotificationCenter]).andReturn(center);

    XCTestExpectation *expect = [self expectationWithDescription:@""];
    [center addObserverForName:kOCTFriendConnectionStatusChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if ([note.object friendNumber] == kFriendNumber) {
            [expect fulfill];
        }
    }];

    [self.submanager tox:self.tox friendConnectionStatusChanged:OCTToxConnectionStatusUDP friendNumber:kFriendNumber];
    [self waitForExpectationsWithTimeout:0.0 handler:nil];
}

#pragma mark -  Helper methods

- (void)stubFriendMethodsInTox
{
    OCMStub([self.tox publicKeyFromFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(kPublicKey);
    OCMStub([self.tox friendNameWithFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(kName);
    OCMStub([self.tox friendStatusMessageWithFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(kStatusMessage);
    OCMStub([self.tox friendStatusWithFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(kStatus);
    OCMStub([self.tox friendConnectionStatusWithFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(kConnectionStatus);
    OCMStub([self.tox friendGetLastOnlineWithFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(sLastSeenOnline);
    OCMStub([self.tox isFriendTypingWithFriendNumber:kFriendNumber error:[OCMArg anyObjectRef]]).andReturn(kIsTyping);
}

- (void)verifyFriend:(OCTFriend *)friend
{
    XCTAssertEqual(friend.friendNumber, kFriendNumber);
    XCTAssertEqualObjects(friend.nickname, kName);
    XCTAssertEqualObjects(friend.publicKey, kPublicKey);
    XCTAssertEqualObjects(friend.name, kName);
    XCTAssertEqualObjects(friend.statusMessage, kStatusMessage);
    XCTAssertEqual(friend.status, kStatus);
    XCTAssertEqual(friend.isConnected, YES);
    XCTAssertEqual(friend.connectionStatus, kConnectionStatus);
    XCTAssertEqual(friend.lastSeenOnlineInterval, [sLastSeenOnline timeIntervalSince1970]);
    XCTAssertEqual(friend.isTyping, kIsTyping);
}

@end
