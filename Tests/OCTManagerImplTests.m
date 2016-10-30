// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTManagerImpl.h"
#import "OCTManagerFactory.h"
#import "OCTManagerConstants.h"
#import "OCTTox.h"
#import "OCTToxAV.h"
#import "OCTToxEncryptSave.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTManagerConfiguration.h"
#import "OCTSubmanagerBootstrapImpl.h"
#import "OCTSubmanagerChatsImpl.h"
#import "OCTSubmanagerDNSImpl.h"
#import "OCTSubmanagerFriendsImpl.h"
#import "OCTSubmanagerFilesImpl.h"
#import "OCTSubmanagerUserImpl.h"
#import "OCTSubmanagerObjectsImpl.h"
#import "OCTSubmanagerCallsImpl.h"
#import "OCTRealmManager.h"
#import "OCTDefaultFileStorage.h"
#import "OCTMessageAbstract.h"
#import "OCTMessageText.h"
#import "OCTMessageFile.h"

static NSString *const kTestDirectory = @"me.dvor.objcToxTests";

@interface OCTManagerImpl (Tests) <OCTSubmanagerDataSource>

@property (strong, nonatomic, readonly) OCTTox *tox;
@property (strong, nonatomic, readonly) OCTToxAV *toxAV;
@property (copy, nonatomic, readwrite) OCTManagerConfiguration *configuration;

@property (strong, nonatomic, readwrite) OCTSubmanagerBootstrapImpl *bootstrap;
@property (strong, nonatomic, readwrite) OCTSubmanagerChatsImpl *chats;
@property (strong, nonatomic, readwrite) OCTSubmanagerDNSImpl *dns;
@property (strong, nonatomic, readwrite) OCTSubmanagerFilesImpl *files;
@property (strong, nonatomic, readwrite) OCTSubmanagerFriendsImpl *friends;
@property (strong, nonatomic, readwrite) OCTSubmanagerObjectsImpl *objects;
@property (strong, nonatomic, readwrite) OCTSubmanagerUserImpl *user;

@property (strong, nonatomic) OCTRealmManager *realmManager;
@property (strong, nonatomic) NSNotificationCenter *notificationCenter;

- (id)forwardingTargetForSelector:(SEL)aSelector;

@end


@interface FakeSubmanager : NSObject <OCTToxDelegate>
@property (weak, nonatomic) id dataSource;
@end
@implementation FakeSubmanager
- (void)tox:(OCTTox *)tox connectionStatus:(OCTToxConnectionStatus)status
{}
@end

@interface OCTManagerImplTests : XCTestCase

@property (strong, nonatomic) OCTManagerImpl *manager;
@property (nonatomic, assign) id mockedCallManager;
@property (strong, nonatomic) id tox;
@property (strong, nonatomic) id toxAV;

@property (strong, nonatomic) NSString *tempDirectoryPath;

@end

@implementation OCTManagerImplTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.tempDirectoryPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:kTestDirectory] stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];

    [[NSFileManager defaultManager] createDirectoryAtPath:self.tempDirectoryPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    self.mockedCallManager = OCMClassMock([OCTSubmanagerCallsImpl class]);

    self.tox = OCMClassMock([OCTTox class]);
    OCMStub([self.tox alloc]).andReturn(self.tox);
    OCMStub([self.tox initWithOptions:[OCMArg any] savedData:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(self.tox);
    OCMStub([self.tox initWithOptions:[OCMArg any] savedData:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(self.tox);
    OCMStub([self.tox save]).andReturn([@"save file" dataUsingEncoding:NSUTF8StringEncoding]);

    self.toxAV = OCMClassMock([OCTToxAV class]);
    OCMStub([self.toxAV alloc]).andReturn(self.toxAV);
    OCMStub([self.toxAV initWithTox:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(self.toxAV);

    id data = OCMClassMock([NSData class]);

    OCMStub([data writeToFile:[OCMArg any] options:NSDataWritingAtomic error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.tox save]).andReturn(data);
}

- (void)tearDown
{
    [self.tox stopMocking];
    self.tox = nil;

    [self.toxAV stopMocking];
    self.toxAV = nil;

    self.manager = nil;
    [self.mockedCallManager stopMocking];
    self.mockedCallManager = nil;

    [[NSFileManager defaultManager] removeItemAtPath:self.tempDirectoryPath error:nil];

    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    [self createManager];

    XCTAssertNotNil(self.manager);

    XCTAssertNotNil(self.manager.bootstrap);
    XCTAssertEqual(self.manager.bootstrap.dataSource, self.manager);
    XCTAssertNotNil(self.manager.chats);
    XCTAssertEqual(self.manager.chats.dataSource, self.manager);
    XCTAssertNotNil(self.manager.dns);
    XCTAssertEqual(self.manager.dns.dataSource, self.manager);
    XCTAssertNotNil(self.manager.files);
    XCTAssertEqual(self.manager.files.dataSource, self.manager);
    XCTAssertNotNil(self.manager.friends);
    XCTAssertEqual(self.manager.friends.dataSource, self.manager);
    XCTAssertNotNil(self.manager.objects);
    XCTAssertEqual(self.manager.objects.dataSource, self.manager);
    XCTAssertNotNil(self.manager.user);
    XCTAssertEqual(self.manager.user.dataSource, self.manager);

    XCTAssertNotNil(self.manager.tox);
    XCTAssertNotNil(self.manager.configuration);
    XCTAssertNotNil(self.manager.realmManager);
    XCTAssertEqualObjects(self.manager.realmManager.realmFileURL.path, self.manager.configuration.fileStorage.pathForDatabase);

    XCTAssertNotNil(self.manager.notificationCenter);
}

- (void)testToxEncryption
{
    // We want use real data to make sure that encryption/decryption actually works. This is really crucial test.
    [self.tox stopMocking];
    self.tox = nil;

    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    configuration.fileStorage = [self temporaryFileStorage];
    __block NSString *userAddress;

    {
        // Create non-encrypted Tox to test manager encryption of first start.
        OCTTox *tox = [[OCTTox alloc] initWithOptions:configuration.options savedData:nil error:nil];
        XCTAssertNotNil(tox);

        userAddress = tox.userAddress;
        [tox setNickname:@"nonEncrypted" error:nil];

        NSData *data = [tox save];
        BOOL result = [data writeToFile:configuration.fileStorage.pathForToxSaveFile
                                options:NSDataWritingAtomic
                                  error:nil];
        XCTAssertTrue(result);
    }

    XCTestExpectation *encryptOnFirstRunExpectation = [self expectationWithDescription:@"encryptOnFirstRunExpectation"];

    [OCTManagerFactory managerWithConfiguration:configuration encryptPassword:@"password123" successBlock:^(id < OCTManager > manager) {
        XCTAssertNotNil(manager);
        XCTAssertEqualObjects(userAddress, manager.user.userAddress);
        XCTAssertEqualObjects(@"nonEncrypted", manager.user.userName);

        [encryptOnFirstRunExpectation fulfill];
    } failureBlock:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];


    XCTestExpectation *encryptedExpectation = [self expectationWithDescription:@"encryptedExpectation"];

    [OCTManagerFactory managerWithConfiguration:configuration encryptPassword:@"password123" successBlock:^(id < OCTManager > manager) {
        XCTAssertNotNil(manager);
        XCTAssertEqualObjects(userAddress, manager.user.userAddress);
        XCTAssertEqualObjects(@"nonEncrypted", manager.user.userName);

        // Change passphrase
        [manager.user setUserName:@"renamed" error:nil];
        [manager changeEncryptPassword:@"new password" oldPassword:@"password123"];

        [encryptedExpectation fulfill];
    } failureBlock:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];


    XCTestExpectation *renamedEncryptedExpectation = [self expectationWithDescription:@"renamedEncryptedExpectation"];

    [OCTManagerFactory managerWithConfiguration:configuration encryptPassword:@"new password" successBlock:^(id < OCTManager > manager) {
        XCTAssertNotNil(manager);
        XCTAssertEqualObjects(userAddress, manager.user.userAddress);
        XCTAssertEqualObjects(@"renamed", manager.user.userName);

        [renamedEncryptedExpectation fulfill];
    } failureBlock:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];


    XCTestExpectation *wrongPasswordExpectation = [self expectationWithDescription:@"wrongPasswordExpectation"];

    [OCTManagerFactory managerWithConfiguration:configuration encryptPassword:@"new password" successBlock:^(id < OCTManager > manager) {
        XCTAssertNotNil(manager);
        XCTAssertFalse([manager changeEncryptPassword:@"the password" oldPassword:@"wrong password"]);

        [wrongPasswordExpectation fulfill];
    } failureBlock:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];


    XCTestExpectation *newPasswordExpectation = [self expectationWithDescription:@"newPasswordExpectation"];

    [OCTManagerFactory managerWithConfiguration:configuration encryptPassword:@"new password" successBlock:^(id < OCTManager > manager) {
        XCTAssertNotNil(manager);
        XCTAssertTrue([manager changeEncryptPassword:@"another" oldPassword:@"new password"]);

        [newPasswordExpectation fulfill];
    } failureBlock:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];


    XCTestExpectation *anotherPasswordExpectation = [self expectationWithDescription:@"anotherPasswordExpectation"];

    [OCTManagerFactory managerWithConfiguration:configuration encryptPassword:@"another" successBlock:^(id < OCTManager > manager) {
        XCTAssertNotNil(manager);

        [anotherPasswordExpectation fulfill];
    } failureBlock:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testIsManagerEncryptedWithPassword
{
    // We want use real data to make sure that encryption/decryption actually works. This is really crucial test.
    [self.tox stopMocking];
    self.tox = nil;

    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    configuration.fileStorage = [self temporaryFileStorage];

    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];

    [OCTManagerFactory managerWithConfiguration:configuration encryptPassword:@"password123" successBlock:^(id < OCTManager > manager) {
        XCTAssertNotNil(manager);
        XCTAssertTrue([manager isManagerEncryptedWithPassword:@"password123"]);
        XCTAssertFalse([manager isManagerEncryptedWithPassword:@"wrong password"]);

        [expectation fulfill];
    } failureBlock:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testDatabaseMigration
{
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    configuration.fileStorage = [self temporaryFileStorage];

    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *bundlePath = [testBundle pathForResource:@"unencrypted-database" ofType:@"realm"];

    [[NSFileManager defaultManager] copyItemAtPath:bundlePath toPath:configuration.fileStorage.pathForDatabase
                                             error:nil];

    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    __block id<OCTManager> manager;

    [OCTManagerFactory managerWithConfiguration:configuration encryptPassword:@"the password" successBlock:^(id < OCTManager > m) {
        manager = m;
        [expectation fulfill];
    } failureBlock:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    XCTAssertNotNil(manager);

    RLMResults *friends = [manager.objects objectsForType:OCTFetchRequestTypeFriend predicate:nil];
    XCTAssertEqual(friends.count, 100);

    for (OCTToxFriendNumber friendNumber = 0; friendNumber < 100; friendNumber++) {
        OCTFriend *friend = friends[friendNumber];

        XCTAssertEqual(friend.friendNumber, friendNumber);
        NSString *nickname = [NSString stringWithFormat:@"friend-%d", friendNumber];
        XCTAssertEqualObjects(friend.nickname, nickname);
    }

    RLMResults *messages = [manager.objects objectsForType:OCTFetchRequestTypeMessageAbstract predicate:nil];
    XCTAssertEqual(messages.count, 50000);

    OCTMessageAbstract *message0 = messages[0];
    XCTAssertNotNil(message0.messageText);
    XCTAssertNil(message0.messageFile);
    XCTAssertNil(message0.messageCall);
    XCTAssertEqualObjects(message0.messageText.text, @"message-0");

    OCTMessageAbstract *message1 = messages[1];
    XCTAssertNil(message1.messageText);
    XCTAssertNotNil(message1.messageFile);
    XCTAssertNil(message1.messageCall);
    XCTAssertEqualObjects(message1.messageFile.fileName, @"file-1");

    XCTAssertEqualObjects(message0.chatUniqueIdentifier, message1.chatUniqueIdentifier);
}

- (void)testConfiguration
{
    OCTToxEncryptSave *encryptSave = OCMClassMock([OCTToxEncryptSave class]);
    OCMStub([(id)encryptSave alloc]).andReturn(encryptSave);
    OCMStub([encryptSave initWithPassphrase:[OCMArg any]
                                    toxData:[OCMArg any]
                                      error:[OCMArg anyObjectRef]]).andReturn(encryptSave);
    OCMStub([encryptSave encryptData:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn([NSData new]);
    OCMStub([encryptSave decryptData:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn([NSData new]);

    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    configuration.options.IPv6Enabled = YES;
    configuration.options.UDPEnabled = YES;
    configuration.options.proxyType = OCTToxProxyTypeHTTP;
    configuration.options.proxyHost = @"proxy.address";
    configuration.options.proxyPort = 999;
    configuration.options.tcpPort = 777;
    configuration.importToxSaveFromPath = @"save.tox";
    configuration.fileStorage = [self temporaryFileStorage];

    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    __block id<OCTManager> manager;

    [OCTManagerFactory managerWithConfiguration:configuration encryptPassword:@"p@s$" successBlock:^(id < OCTManager > m) {
        manager = m;
        [expectation fulfill];
    } failureBlock:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    OCTManagerConfiguration *c2 = [manager configuration];

    XCTAssertEqualObjects(configuration.fileStorage, c2.fileStorage);
    XCTAssertEqual(configuration.options.IPv6Enabled, c2.options.IPv6Enabled);
    XCTAssertEqual(configuration.options.UDPEnabled, c2.options.UDPEnabled);
    XCTAssertEqual(configuration.options.proxyType, c2.options.proxyType);
    XCTAssertEqualObjects(configuration.options.proxyHost, c2.options.proxyHost);
    XCTAssertEqual(configuration.options.proxyPort, c2.options.proxyPort);
    XCTAssertEqual(configuration.options.tcpPort, c2.options.tcpPort);
    XCTAssertEqualObjects(configuration.importToxSaveFromPath, c2.importToxSaveFromPath);

    [(id)encryptSave stopMocking];
}

- (void)testSubmanagerDataSource
{
    [self createManager];

    XCTAssertEqual([self.manager managerGetTox], self.manager.tox);
    XCTAssertEqual([self.manager managerGetRealmManager], self.manager.realmManager);
    XCTAssertEqual([self.manager managerGetFileStorage], self.manager.configuration.fileStorage);
    XCTAssertEqual([self.manager managerGetNotificationCenter], self.manager.notificationCenter);
}

- (void)testForwardTargetForSelector
{
    [self createManager];

    id submanager = [FakeSubmanager new];
    self.manager.bootstrap = submanager;
    self.manager.chats = submanager;
    self.manager.dns = submanager;
    self.manager.files = submanager;
    self.manager.friends = submanager;
    self.manager.objects = submanager;
    self.manager.user = submanager;

    // test non protocol selector
    XCTAssertNil([self.manager forwardingTargetForSelector:@selector(dataSource)]);

    // test for protocol non-implemented selector
    XCTAssertNil([self.manager forwardingTargetForSelector:@selector(tox:friendRequestWithMessage:publicKey:)]);

    // test for protocol implemented selector
    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);
}

- (void)testForwardTargetForSelector2
{
    [self createManager];

    id submanager = [FakeSubmanager new];
    id dummy = [NSObject new];

    self.manager.bootstrap = submanager;
    self.manager.chats = dummy;
    self.manager.dns = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.bootstrap = dummy;
    self.manager.chats = submanager;
    self.manager.dns = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.dns = submanager;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.dns = dummy;
    self.manager.files = submanager;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.dns = dummy;
    self.manager.files = dummy;
    self.manager.friends = submanager;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.dns = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = submanager;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.dns = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = submanager;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);
}

- (void)testExportToxSaveFile
{
    [self createManager];

    NSString *path = [self.manager exportToxSaveFileAndReturnError:nil];
    NSString *result = [[self.manager configuration].fileStorage.pathForTemporaryFilesDirectory stringByAppendingPathComponent:@"save.tox"];
    XCTAssertEqualObjects(path, result);
}

#pragma mark -  Helper methods

- (void)createManager
{
    OCMStub([[self.mockedCallManager alloc] initWithTox:[OCMArg anyPointer]]).andReturn(nil);
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];

    configuration.fileStorage = [self temporaryFileStorage];

    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    __weak OCTManagerImplTests *weakSelf = self;

    [OCTManagerFactory managerWithConfiguration:configuration encryptPassword:@"123" successBlock:^(id < OCTManager > manager) {
        weakSelf.manager = (OCTManagerImpl *)manager;
        [expectation fulfill];
    } failureBlock:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (OCTDefaultFileStorage *)temporaryFileStorage
{
    return [[OCTDefaultFileStorage alloc] initWithBaseDirectory:self.tempDirectoryPath
                                             temporaryDirectory:[self.tempDirectoryPath stringByAppendingPathComponent:@"tmp"]];
}

@end
