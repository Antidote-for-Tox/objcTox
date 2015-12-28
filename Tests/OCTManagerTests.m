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
#import "OCTSubmanagerAvatars+Private.h"
#import "OCTSubmanagerBootstrap+Private.h"
#import "OCTSubmanagerChats+Private.h"
#import "OCTSubmanagerDNS+Private.h"
#import "OCTSubmanagerFriends+Private.h"
#import "OCTSubmanagerFiles+Private.h"
#import "OCTSubmanagerUser+Private.h"
#import "OCTSubmanagerObjects+Private.h"
#import "OCTSubmanagerCalls+Private.h"
#import "OCTRealmManager.h"

@interface OCTManager (Tests) <OCTSubmanagerDataSource>

@property (strong, nonatomic, readonly) OCTTox *tox;
@property (strong, nonatomic, readonly) OCTToxAV *toxAV;
@property (copy, nonatomic, readwrite) OCTManagerConfiguration *configuration;

@property (strong, nonatomic, readwrite) OCTSubmanagerAvatars *avatars;
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

@end

@implementation OCTManagerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.mockedCallManager = OCMClassMock([OCTSubmanagerCalls class]);

    self.tox = OCMClassMock([OCTTox class]);
    OCMStub([self.tox alloc]).andReturn(self.tox);
    OCMStub([self.tox initWithOptions:[OCMArg any] savedData:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(self.tox);

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
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    [self createManager];

    XCTAssertNotNil(self.manager);

    XCTAssertNotNil(self.manager.avatars);
    XCTAssertEqual(self.manager.avatars.dataSource, self.manager);
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
    XCTAssertEqualObjects(self.manager.realmManager.path, self.manager.configuration.fileStorage.pathForDatabase);

    XCTAssertNotNil(self.manager.notificationCenter);
}

- (void)testEncryption
{
    // We want use real data to make sure that encryption/decryption actually works. This is really crucial test.
    [self.tox stopMocking];
    self.tox = nil;

    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];

    // Just in case, removing leftovers from other tests.
    [[NSFileManager defaultManager] removeItemAtPath:configuration.fileStorage.pathForToxSaveFile error:nil];

    NSString *userAddress;

    {
        OCTManager *nonEncrypted = [[OCTManager alloc] initWithConfiguration:configuration error:nil];
        XCTAssertNotNil(nonEncrypted);

        userAddress = nonEncrypted.user.userAddress;
        [nonEncrypted.user setUserName:@"nonEncrypted" error:nil];

        // Encrypting
        [nonEncrypted changePassphrase:@"password123"];
        nonEncrypted = nil;
    }

    configuration.passphrase = @"password123";

    {
        OCTManager *encrypted = [[OCTManager alloc] initWithConfiguration:configuration error:nil];
        XCTAssertNotNil(encrypted);
        XCTAssertEqualObjects(userAddress, encrypted.user.userAddress);
        XCTAssertEqualObjects(@"nonEncrypted", encrypted.user.userName);

        // Change passphrase
        [encrypted.user setUserName:@"renamed" error:nil];
        [encrypted changePassphrase:@"$ecur!"];
        encrypted = nil;
    }

    configuration.passphrase = @"$ecur!";

    {
        OCTManager *renamedEncrypted = [[OCTManager alloc] initWithConfiguration:configuration error:nil];
        XCTAssertNotNil(renamedEncrypted);
        XCTAssertEqualObjects(userAddress, renamedEncrypted.user.userAddress);
        XCTAssertEqualObjects(@"renamed", renamedEncrypted.user.userName);

        // Remove passphrase
        [renamedEncrypted.user setUserName:@"removed" error:nil];
        [renamedEncrypted changePassphrase:nil];
        renamedEncrypted = nil;
    }

    configuration.passphrase = nil;

    {
        OCTManager *removed = [[OCTManager alloc] initWithConfiguration:configuration error:nil];
        XCTAssertNotNil(removed);
        XCTAssertEqualObjects(userAddress, removed.user.userAddress);
        XCTAssertEqualObjects(@"removed", removed.user.userName);

        // Encrypt again
        [removed.user setUserName:@"again" error:nil];
        [removed changePassphrase:@"@g@!n"];
        removed = nil;
    }

    configuration.passphrase = @"@g@!n";

    {
        OCTManager *again = [[OCTManager alloc] initWithConfiguration:configuration error:nil];
        XCTAssertNotNil(again);
        XCTAssertEqualObjects(userAddress, again.user.userAddress);
        XCTAssertEqualObjects(@"again", again.user.userName);
    }

    configuration.passphrase = nil;

    {
        NSError *error;
        OCTManager *noPassword = [[OCTManager alloc] initWithConfiguration:configuration error:&error];
        XCTAssertNil(noPassword);
        XCTAssertEqualObjects(error.domain, kOCTManagerErrorDomain);
        XCTAssertEqual(error.code, OCTManagerInitErrorCreateToxEncrypted);
    }

    configuration.passphrase = @"wrong password";

    {
        NSError *error;
        OCTManager *wrongPassword = [[OCTManager alloc] initWithConfiguration:configuration error:&error];
        XCTAssertNil(wrongPassword);
        XCTAssertEqualObjects(error.domain, kOCTManagerErrorDomain);
        XCTAssertEqual(error.code, OCTManagerInitErrorDecryptFailed);
    }

    // Cleaning up
    [[NSFileManager defaultManager] removeItemAtPath:configuration.fileStorage.pathForToxSaveFile error:nil];
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
    configuration.passphrase = @"p@s$";

    OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration error:nil];

    OCTManagerConfiguration *c2 = [manager configuration];

    XCTAssertEqualObjects(configuration.fileStorage, c2.fileStorage);
    XCTAssertEqual(configuration.options.IPv6Enabled, c2.options.IPv6Enabled);
    XCTAssertEqual(configuration.options.UDPEnabled, c2.options.UDPEnabled);
    XCTAssertEqual(configuration.options.proxyType, c2.options.proxyType);
    XCTAssertEqualObjects(configuration.options.proxyHost, c2.options.proxyHost);
    XCTAssertEqual(configuration.options.proxyPort, c2.options.proxyPort);
    XCTAssertEqual(configuration.options.tcpPort, c2.options.tcpPort);
    XCTAssertEqualObjects(configuration.importToxSaveFromPath, c2.importToxSaveFromPath);
    XCTAssertEqualObjects(configuration.passphrase, c2.passphrase);

    [manager changePassphrase:@"123456"];

    OCTManagerConfiguration *c3 = [manager configuration];

    XCTAssertEqualObjects(@"123456", c3.passphrase);

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
    self.manager.avatars = submanager;
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

    self.manager.avatars = submanager;
    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.dns = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = submanager;
    self.manager.chats = dummy;
    self.manager.dns = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = dummy;
    self.manager.chats = submanager;
    self.manager.dns = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.dns = submanager;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.dns = dummy;
    self.manager.files = submanager;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.dns = dummy;
    self.manager.files = dummy;
    self.manager.friends = submanager;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.dns = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = submanager;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
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
    id configuration = OCMClassMock([OCTManagerConfiguration class]);
    id storage = OCMProtocolMock(@protocol(OCTFileStorageProtocol));
    OCMStub([configuration fileStorage]).andReturn(storage);
    OCMStub([configuration copy]).andReturn(configuration);
    OCMStub([storage pathForToxSaveFile]).andReturn(@"somewhere/tox.save");
    OCMStub([storage pathForTemporaryFilesDirectory]).andReturn(@"tmp");

    id fileManager = OCMClassMock([NSFileManager class]);
    OCMStub([fileManager defaultManager]).andReturn(fileManager);
    OCMExpect([fileManager copyItemAtPath:@"somewhere/tox.save" toPath:@"tmp/tox.save" error:[OCMArg anyObjectRef]]).andReturn(YES);

    id realmManager = OCMClassMock([OCTRealmManager class]);
    OCMStub([realmManager alloc]).andReturn(realmManager);
    OCMStub([realmManager initWithDatabasePath:[OCMArg any]]).andReturn(realmManager);

    OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration error:nil];

    NSString *path = [manager exportToxSaveFile:nil];

    XCTAssertEqualObjects(path, @"tmp/tox.save");
    OCMVerifyAll(fileManager);

    [fileManager stopMocking];
    [realmManager stopMocking];
    fileManager = nil;
    realmManager = nil;
}

#pragma mark -  Helper methods

- (void)createManager
{
    OCMStub([[self.mockedCallManager alloc] initWithTox:[OCMArg anyPointer]]).andReturn(nil);
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    self.manager = [[OCTManager alloc] initWithConfiguration:configuration error:nil];
}

@end
