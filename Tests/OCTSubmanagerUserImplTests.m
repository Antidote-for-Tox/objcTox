// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTRealmTests.h"
#import "OCTSubmanagerUserImpl.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTTox.h"

@interface OCTSubmanagerUserImplTests : OCTRealmTests

@property (strong, nonatomic) OCTSubmanagerUserImpl *submanager;
@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) id tox;

@end

@implementation OCTSubmanagerUserImplTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.tox = OCMClassMock([OCTTox class]);

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));
    OCMStub([self.dataSource managerGetTox]).andReturn(self.tox);
    OCMStub([self.dataSource managerGetRealmManager]).andReturn(self.realmManager);

    self.submanager = [OCTSubmanagerUserImpl new];
    self.submanager.dataSource = self.dataSource;
}

- (void)tearDown
{
    self.tox = nil;
    self.dataSource = nil;
    self.submanager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testConnectionStatus
{
    OCMStub([self.tox connectionStatus]).andReturn(OCTToxConnectionStatusTCP);
    XCTAssertEqual([self.submanager connectionStatus], OCTToxConnectionStatusTCP);
}

- (void)testUserAddress
{
    OCMStub([self.tox userAddress]).andReturn(@"address");
    XCTAssertEqualObjects([self.submanager userAddress], @"address");
}

- (void)testPublicKey
{
    OCMStub([self.tox publicKey]).andReturn(@"publicKey");
    XCTAssertEqualObjects([self.submanager publicKey], @"publicKey");
}

- (void)testNospam
{
    OCMStub([self.tox nospam]).andReturn(5);
    XCTAssertEqual([self.submanager nospam], 5);

    self.submanager.nospam = 7;
    OCMVerify([self.tox setNospam:7]);
    OCMVerify([self.dataSource managerSaveTox]);
}

- (void)testUserStatus
{
    OCMStub([self.tox userStatus]).andReturn(5);
    XCTAssertEqual([self.submanager userStatus], 5);

    self.submanager.userStatus = 7;
    OCMVerify([self.tox setUserStatus:7]);
    OCMVerify([self.dataSource managerSaveTox]);
}

- (void)testUserName
{
    OCMStub([self.tox userName]).andReturn(@"userName");
    XCTAssertEqualObjects([self.submanager userName], @"userName");

    NSError *error, *error2;
    OCMExpect([self.tox setNickname:@"name" error:[OCMArg setTo:error2]]).andReturn(YES);

    [self.submanager setUserName:@"name" error:&error];

    XCTAssertEqual(error, error2);
    OCMVerifyAll(self.tox);
    OCMVerify([self.dataSource managerSaveTox]);
}

- (void)testUserStatusMessage
{
    OCMStub([self.tox userStatusMessage]).andReturn(@"userStatusMessage");
    XCTAssertEqualObjects([self.submanager userStatusMessage], @"userStatusMessage");

    NSError *error, *error2;
    OCMExpect([self.tox setUserStatusMessage:@"message" error:[OCMArg setTo:error2]]).andReturn(YES);

    [self.submanager setUserStatusMessage:@"message" error:&error];

    XCTAssertEqual(error, error2);
    OCMVerifyAll(self.tox);
    OCMVerify([self.dataSource managerSaveTox]);
}

- (void)testSetUserAvatar
{
    char databytes[65536];
    NSData *data = [[NSData alloc] initWithBytes:databytes length:65536];
    XCTAssertTrue([self.submanager setUserAvatar:data error:nil]);

    XCTAssertEqualObjects([self.submanager userAvatar], data);

    char toomanybytes[85536];
    data = [[NSData alloc] initWithBytes:toomanybytes length:85536];
    XCTAssertFalse([self.submanager setUserAvatar:data error:nil]);

    XCTAssertTrue([self.submanager setUserAvatar:nil error:nil]);
    XCTAssertNil([self.submanager userAvatar]);
}

@end
