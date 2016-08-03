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
#import "OCTManagerConstants.h"
#import "OCTTox.h"
#import "OCTToxAV.h"
#import "OCTToxEncryptSave.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTManagerConfiguration.h"
#import "OCTSubmanagerBootstrap+Private.h"
#import "OCTSubmanagerChats+Private.h"
#import "OCTSubmanagerDNS+Private.h"
#import "OCTSubmanagerFriends+Private.h"
#import "OCTSubmanagerFiles+Private.h"
#import "OCTSubmanagerUser+Private.h"
#import "OCTSubmanagerObjects+Private.h"
#import "OCTSubmanagerCalls+Private.h"
#import "OCTRealmManager.h"
#import "OCTDefaultFileStorage.h"

static NSString *const kTestDirectory = @"me.dvor.objcToxTests";

@interface OCTManager (Tests) <OCTSubmanagerDataSource>

@property (strong, nonatomic, readonly) OCTTox *tox;
@property (strong, nonatomic, readonly) OCTToxAV *toxAV;
@property (copy, nonatomic, readwrite) OCTManagerConfiguration *configuration;

@property (strong, nonatomic, readwrite) OCTSubmanagerBootstrap *bootstrap;
@property (strong, nonatomic, readwrite) OCTSubmanagerChats *chats;
@property (strong, nonatomic, readwrite) OCTSubmanagerDNS *dns;
@property (strong, nonatomic, readwrite) OCTSubmanagerFiles *files;
@property (strong, nonatomic, readwrite) OCTSubmanagerFriends *friends;
@property (strong, nonatomic, readwrite) OCTSubmanagerObjects *objects;
@property (strong, nonatomic, readwrite) OCTSubmanagerUser *user;

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

@interface OCTManagerTests : XCTestCase

@property (strong, nonatomic) OCTManager *manager;
@property (nonatomic, assign) id mockedCallManager;
@property (strong, nonatomic) id tox;
@property (strong, nonatomic) id toxAV;

@property (strong, nonatomic) NSString *tempDirectoryPath;

@end

@implementation OCTManagerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.tempDirectoryPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:kTestDirectory] stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];

    [[NSFileManager defaultManager] createDirectoryAtPath:self.tempDirectoryPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    self.mockedCallManager = OCMClassMock([OCTSubmanagerCalls class]);

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

    NSString *userAddress;

    {
        OCTManager *nonEncrypted = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"123" error:nil];
        XCTAssertNotNil(nonEncrypted);

        userAddress = nonEncrypted.user.userAddress;
        [nonEncrypted.user setUserName:@"nonEncrypted" error:nil];

        // Encrypting
        [nonEncrypted changeToxPassword:@"password123" oldPassword:nil];
        nonEncrypted = nil;
    }

    {
        OCTManager *encrypted = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:@"password123" databasePassword:@"123" error:nil];
        XCTAssertNotNil(encrypted);
        XCTAssertEqualObjects(userAddress, encrypted.user.userAddress);
        XCTAssertEqualObjects(@"nonEncrypted", encrypted.user.userName);

        // Change passphrase
        [encrypted.user setUserName:@"renamed" error:nil];
        [encrypted changeToxPassword:@"$ecur!" oldPassword:@"password123"];
        encrypted = nil;
    }

    {
        OCTManager *renamedEncrypted = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:@"$ecur!" databasePassword:@"123" error:nil];
        XCTAssertNotNil(renamedEncrypted);
        XCTAssertEqualObjects(userAddress, renamedEncrypted.user.userAddress);
        XCTAssertEqualObjects(@"renamed", renamedEncrypted.user.userName);

        // Remove passphrase
        [renamedEncrypted.user setUserName:@"removed" error:nil];
        [renamedEncrypted changeToxPassword:nil oldPassword:@"$ecur!"];
        renamedEncrypted = nil;
    }

    {
        OCTManager *removed = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"123" error:nil];
        XCTAssertNotNil(removed);
        XCTAssertEqualObjects(userAddress, removed.user.userAddress);
        XCTAssertEqualObjects(@"removed", removed.user.userName);

        // Encrypt again
        [removed.user setUserName:@"again" error:nil];
        [removed changeToxPassword:@"@g@!n" oldPassword:nil];
        removed = nil;
    }

    {
        OCTManager *again = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:@"@g@!n" databasePassword:@"123" error:nil];
        XCTAssertNotNil(again);
        XCTAssertEqualObjects(userAddress, again.user.userAddress);
        XCTAssertEqualObjects(@"again", again.user.userName);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:@"@g@!n" databasePassword:@"123" error:nil];
        XCTAssertNotNil(manager);

        XCTAssertTrue([manager changeToxPassword:@"new password" oldPassword:@"@g@!n"]);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:@"new password" databasePassword:@"123" error:nil];
        XCTAssertNotNil(manager);

        XCTAssertFalse([manager changeToxPassword:@"the password" oldPassword:@"wrong password"]);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:@"new password" databasePassword:@"123" error:nil];
        XCTAssertNotNil(manager);

        XCTAssertTrue([manager changeToxPassword:nil oldPassword:@"new password"]);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"123" error:nil];
        XCTAssertNotNil(manager);

        XCTAssertFalse([manager changeToxPassword:@"the password" oldPassword:@"there should be no password"]);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"123" error:nil];
        XCTAssertNotNil(manager);

        XCTAssertTrue([manager changeToxPassword:@"same password" oldPassword:nil]);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:@"same password" databasePassword:@"123" error:nil];
        XCTAssertNotNil(manager);

        XCTAssertTrue([manager changeToxPassword:@"same password" oldPassword:@"same password"]);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:@"same password" databasePassword:@"123" error:nil];
        XCTAssertNotNil(manager);

        XCTAssertTrue([manager changeToxPassword:@"the password" oldPassword:@"same password"]);
    }

    {
        NSError *error;
        OCTManager *noPassword = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"123" error:&error];
        XCTAssertNil(noPassword);
        XCTAssertEqualObjects(error.domain, kOCTManagerErrorDomain);
        XCTAssertEqual(error.code, OCTManagerInitErrorCreateToxEncrypted);
    }

    {
        NSError *error;
        OCTManager *wrongPassword = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:@"wrong password" databasePassword:@"123" error:&error];
        XCTAssertNil(wrongPassword);
        XCTAssertEqualObjects(error.domain, kOCTManagerErrorDomain);
        XCTAssertEqual(error.code, OCTManagerInitErrorToxFileDecryptFailed);
    }
}

- (void)testDatabaseEncryption
{
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    configuration.fileStorage = [self temporaryFileStorage];

    {
        OCTManager *newDatabase = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"123" error:nil];
        XCTAssertNotNil(newDatabase);
    }

    {
        OCTManager *sameDatabase = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"123" error:nil];
        XCTAssertNotNil(sameDatabase);
    }

    {
        NSError *error;
        OCTManager *wrongPassword = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"wrong password" error:&error];

        XCTAssertNil(wrongPassword);
        XCTAssertEqual(error.code, OCTManagerInitErrorDatabaseKeyDecryptFailed);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"123" error:nil];
        XCTAssertNotNil(manager);

        XCTAssertTrue([manager changeDatabasePassword:@"the pass" oldPassword:@"123"]);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"123" error:nil];
        XCTAssertNil(manager);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"the pass" error:nil];
        XCTAssertNotNil(manager);

        XCTAssertFalse([manager changeDatabasePassword:@"who cares" oldPassword:@"wrong pass"]);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"the pass" error:nil];
        XCTAssertNotNil(manager);

        XCTAssertTrue([manager changeDatabasePassword:@"final pass" oldPassword:@"the pass"]);
    }

    {
        OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"final pass" error:nil];
        XCTAssertNotNil(manager);
    }
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

    OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:@"p@s$" databasePassword:@"123" error:nil];

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

    NSString *path = [self.manager exportToxSaveFile:nil];
    NSString *result = [[self.manager configuration].fileStorage.pathForTemporaryFilesDirectory stringByAppendingPathComponent:@"save.tox"];
    XCTAssertEqualObjects(path, result);
}

#pragma mark -  Helper methods

- (void)createManager
{
    OCMStub([[self.mockedCallManager alloc] initWithTox:[OCMArg anyPointer]]).andReturn(nil);
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];

    configuration.fileStorage = [self temporaryFileStorage];

    self.manager = [[OCTManager alloc] initWithConfiguration:configuration toxPassword:nil databasePassword:@"123" error:nil];
}

- (OCTDefaultFileStorage *)temporaryFileStorage
{
    return [[OCTDefaultFileStorage alloc] initWithBaseDirectory:self.tempDirectoryPath
                                             temporaryDirectory:[self.tempDirectoryPath stringByAppendingPathComponent:@"tmp"]];
}

@end
