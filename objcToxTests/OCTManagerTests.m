//
//  OCTManagerTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTManager.h"
#import "OCTTox.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTSubmanagerAvatars+Private.h"
#import "OCTSubmanagerChats+Private.h"
#import "OCTSubmanagerFriends+Private.h"
#import "OCTSubmanagerFiles+Private.h"
#import "OCTSubmanagerUser+Private.h"
#import "OCTDBManager.h"

@interface OCTManager (Tests) <OCTSubmanagerDataSource>

@property (strong, nonatomic, readonly) OCTTox *tox;
@property (copy, nonatomic, readonly) OCTManagerConfiguration *configuration;

@property (strong, nonatomic, readwrite) OCTSubmanagerUser *user;
@property (strong, nonatomic, readwrite) OCTSubmanagerFriends *friends;
@property (strong, nonatomic, readwrite) OCTSubmanagerChats *chats;
@property (strong, nonatomic, readwrite) OCTSubmanagerFiles *files;
@property (strong, nonatomic, readwrite) OCTSubmanagerAvatars *avatars;

@property (strong, nonatomic) OCTDBManager *dbManager;

- (id)forwardingTargetForSelector:(SEL)aSelector;

@end


@interface FakeSubmanager : NSObject <OCTToxDelegate>
@property (weak, nonatomic) id dataSource;
@end
@implementation FakeSubmanager
- (void)tox:(OCTTox *)tox connectionStatus:(OCTToxConnectionStatus)status
{}
@end

@interface OCTManagerTests : XCTestCase

@property (strong, nonatomic) OCTManager *manager;

@end

@implementation OCTManagerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    self.manager = [[OCTManager alloc] initWithConfiguration:configuration];
}

- (void)tearDown
{
    self.manager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.manager);
    XCTAssertNotNil(self.manager.user);
    XCTAssertEqual(self.manager.user.dataSource, self.manager);
    XCTAssertNotNil(self.manager.friends);
    XCTAssertEqual(self.manager.friends.dataSource, self.manager);
    XCTAssertNotNil(self.manager.chats);
    XCTAssertEqual(self.manager.chats.dataSource, self.manager);
    XCTAssertNotNil(self.manager.files);
    XCTAssertEqual(self.manager.files.dataSource, self.manager);
    XCTAssertNotNil(self.manager.avatars);
    XCTAssertEqual(self.manager.avatars.dataSource, self.manager);
    XCTAssertNotNil(self.manager.tox);
    XCTAssertNotNil(self.manager.configuration);
    XCTAssertNotNil(self.manager.dbManager);
    XCTAssertEqualObjects(self.manager.dbManager.path, self.manager.configuration.fileStorage.pathForDatabase);
}

- (void)testBootstrap
{
    NSError *error, *error2;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox alloc]).andReturn(tox);
    OCMStub([tox initWithOptions:[OCMArg any] savedData:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(tox);
    OCMExpect([tox bootstrapFromHost:@"host" port:10 publicKey:@"publicKey" error:[OCMArg setTo:error2]]).andReturn(YES);

    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration];

    BOOL result = [manager bootstrapFromHost:@"host" port:10 publicKey:@"publicKey" error:&error];

    XCTAssertTrue(result);
    XCTAssertEqual(error, error2);
    OCMVerifyAll(tox);

    tox = nil;
}

- (void)testAddTCPRelay
{
    NSError *error, *error2;

    id tox = OCMClassMock([OCTTox class]);
    OCMStub([tox alloc]).andReturn(tox);
    OCMStub([tox initWithOptions:[OCMArg any] savedData:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(tox);
    OCMExpect([tox addTCPRelayWithHost:@"host" port:10 publicKey:@"publicKey" error:[OCMArg setTo:error2]]).andReturn(YES);

    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration];

    BOOL result = [manager addTCPRelayWithHost:@"host" port:10 publicKey:@"publicKey" error:&error];

    XCTAssertTrue(result);
    XCTAssertEqual(error, error2);
    OCMVerifyAll(tox);

    tox = nil;
}

- (void)testSubmanagerDataSource
{
    XCTAssertEqual([self.manager managerGetTox], self.manager.tox);
    XCTAssertEqual([self.manager managerGetDBManager], self.manager.dbManager);
    XCTAssertEqual([self.manager managerGetSettingsStorage], self.manager.configuration.settingsStorage);
    XCTAssertEqual([self.manager managerGetFileStorage], self.manager.configuration.fileStorage);
}

- (void)testForwardTargetForSelector
{
    id submanager = [FakeSubmanager new];
    self.manager.user = submanager;
    self.manager.friends = submanager;
    self.manager.chats = submanager;
    self.manager.files = submanager;
    self.manager.avatars = submanager;

    // test non protocol selector
    XCTAssertNil([self.manager forwardingTargetForSelector:@selector(dataSource)]);

    // test for protocol non-implemented selector
    XCTAssertNil([self.manager forwardingTargetForSelector:@selector(tox:friendRequestWithMessage:publicKey:)]);

    // test for protocol implemented selector
    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);
}

- (void)testForwardTargetForSelector2
{
    id submanager = [FakeSubmanager new];
    id dummy = [NSObject new];

    self.manager.user = submanager;
    self.manager.friends = dummy;
    self.manager.chats = dummy;
    self.manager.files = dummy;
    self.manager.avatars = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.user = dummy;
    self.manager.friends = submanager;
    self.manager.chats = dummy;
    self.manager.files = dummy;
    self.manager.avatars = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.user = dummy;
    self.manager.friends = dummy;
    self.manager.chats = dummy;
    self.manager.files = submanager;
    self.manager.avatars = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.user = dummy;
    self.manager.friends = dummy;
    self.manager.chats = submanager;
    self.manager.files = dummy;
    self.manager.avatars = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.user = dummy;
    self.manager.friends = dummy;
    self.manager.chats = dummy;
    self.manager.files = dummy;
    self.manager.avatars = submanager;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);
}

@end
