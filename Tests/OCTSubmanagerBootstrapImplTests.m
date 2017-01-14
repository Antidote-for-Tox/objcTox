// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "OCTSubmanagerBootstrapImpl.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTTox.h"
#import "OCTRealmManager.h"
#import "OCTSettingsStorageObject.h"
#import "OCTNode.h"

@interface OCTSubmanagerBootstrapImpl (Tests)

@property (strong, nonatomic) NSMutableSet *addedNodes;

@property (assign, nonatomic) NSTimeInterval didConnectDelay;
@property (assign, nonatomic) NSTimeInterval iterationTime;

@end

@interface OCTSubmanagerBootstrapImplTests : XCTestCase

@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) id tox;
@property (strong, nonatomic) id realmManager;
@property (strong, nonatomic) id settingsStorage;
@property (strong, nonatomic) OCTSubmanagerBootstrapImpl *submanager;

@end

@implementation OCTSubmanagerBootstrapImplTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));
    // self.tox = OCMClassMock([OCTTox class]);
    self.tox = OCMStrictClassMock([OCTTox class]);
    self.realmManager = OCMClassMock([OCTRealmManager class]);
    self.settingsStorage = OCMClassMock([OCTSettingsStorageObject class]);

    OCMStub([self.dataSource managerGetTox]).andReturn(self.tox);
    OCMStub([self.dataSource managerGetRealmManager]).andReturn(self.realmManager);
    OCMStub([self.realmManager settingsStorage]).andReturn(self.settingsStorage);

    self.submanager = [OCTSubmanagerBootstrapImpl new];
    self.submanager.dataSource = self.dataSource;
}

- (void)tearDown
{
    self.dataSource = nil;
    self.tox = nil;
    self.realmManager = nil;
    self.settingsStorage = nil;
    self.submanager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAddPredefinedNodes
{
    [self.submanager addPredefinedNodes];

    XCTAssertTrue(self.submanager.addedNodes.count > 0);

    for (OCTNode *node in self.submanager.addedNodes) {
        XCTAssertTrue(node.ipv4Host.length > 0);
        XCTAssertTrue(node.udpPort > 0);
        XCTAssertNotNil(node.tcpPorts);
        XCTAssertEqual(node.publicKey.length, kOCTToxPublicKeyLength);
    }
}

- (void)testBootstrapCustomNodes
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"bootstrap"];

    self.submanager.didConnectDelay = 0.0;
    self.submanager.iterationTime = 0.05;

    [self.submanager addNodeWithIpv4Host:@"one" ipv6Host:@"one6" udpPort:1 tcpPorts:@[@1, @11] publicKey:@"1"];
    [self.submanager addNodeWithIpv4Host:@"two" ipv6Host:nil udpPort:2 tcpPorts:@[@2] publicKey:@"2"];
    [self.submanager addNodeWithIpv4Host:nil ipv6Host:@"three6" udpPort:3 tcpPorts:@[@3] publicKey:@"3"];
    [self.submanager addNodeWithIpv4Host:@"four" ipv6Host:@"four6" udpPort:4 tcpPorts:@[] publicKey:@"4"];

    OCMExpect([self.tox bootstrapFromHost:@"one" port:1 publicKey:@"1" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox bootstrapFromHost:@"one6" port:1 publicKey:@"1" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox addTCPRelayWithHost:@"one" port:1 publicKey:@"1" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox addTCPRelayWithHost:@"one6" port:1 publicKey:@"1" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox addTCPRelayWithHost:@"one" port:11 publicKey:@"1" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox addTCPRelayWithHost:@"one6" port:11 publicKey:@"1" error:[OCMArg anyObjectRef]]);

    OCMExpect([self.tox bootstrapFromHost:@"two" port:2 publicKey:@"2" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox addTCPRelayWithHost:@"two" port:2 publicKey:@"2" error:[OCMArg anyObjectRef]]);

    OCMExpect([self.tox bootstrapFromHost:@"three6" port:3 publicKey:@"3" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox addTCPRelayWithHost:@"three6" port:3 publicKey:@"3" error:[OCMArg anyObjectRef]]);

    OCMExpect([self.tox bootstrapFromHost:@"four" port:4 publicKey:@"4" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox bootstrapFromHost:@"four6" port:4 publicKey:@"4" error:[OCMArg anyObjectRef]]);

    [self.submanager bootstrap];

    [self performBlock:^{
        [expectation fulfill];
    } afterDelay:0.1];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];

    OCMVerifyAll(self.tox);
}

- (void)testBootstrapSeveralPortions
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"bootstrap"];

    self.submanager.didConnectDelay = 0.0;
    self.submanager.iterationTime = 0.1;

    [self.submanager addNodeWithIpv4Host:@"h1" ipv6Host:nil udpPort:1 tcpPorts:@[] publicKey:@"1"];
    [self.submanager addNodeWithIpv4Host:@"h2" ipv6Host:nil udpPort:2 tcpPorts:@[] publicKey:@"2"];
    [self.submanager addNodeWithIpv4Host:@"h3" ipv6Host:nil udpPort:3 tcpPorts:@[] publicKey:@"3"];
    [self.submanager addNodeWithIpv4Host:@"h4" ipv6Host:nil udpPort:4 tcpPorts:@[] publicKey:@"4"];
    [self.submanager addNodeWithIpv4Host:@"h5" ipv6Host:nil udpPort:5 tcpPorts:@[] publicKey:@"5"];
    [self.submanager addNodeWithIpv4Host:@"h6" ipv6Host:nil udpPort:6 tcpPorts:@[] publicKey:@"6"];
    [self.submanager addNodeWithIpv4Host:@"h7" ipv6Host:nil udpPort:7 tcpPorts:@[] publicKey:@"7"];
    [self.submanager addNodeWithIpv4Host:@"h8" ipv6Host:nil udpPort:8 tcpPorts:@[] publicKey:@"8"];
    [self.submanager addNodeWithIpv4Host:@"h9" ipv6Host:nil udpPort:9 tcpPorts:@[] publicKey:@"9"];
    [self.submanager addNodeWithIpv4Host:@"h10" ipv6Host:nil udpPort:10 tcpPorts:@[] publicKey:@"10"];

    OCMExpect([self.tox bootstrapFromHost:@"h1" port:1 publicKey:@"1" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox bootstrapFromHost:@"h2" port:2 publicKey:@"2" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox bootstrapFromHost:@"h3" port:3 publicKey:@"3" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox bootstrapFromHost:@"h4" port:4 publicKey:@"4" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox bootstrapFromHost:@"h5" port:5 publicKey:@"5" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox bootstrapFromHost:@"h6" port:6 publicKey:@"6" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox bootstrapFromHost:@"h7" port:7 publicKey:@"7" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox bootstrapFromHost:@"h8" port:8 publicKey:@"8" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox bootstrapFromHost:@"h9" port:9 publicKey:@"9" error:[OCMArg anyObjectRef]]);
    OCMExpect([self.tox bootstrapFromHost:@"h10" port:10 publicKey:@"10" error:[OCMArg anyObjectRef]]);

    [self.submanager bootstrap];

    [self performBlock:^{
        [expectation fulfill];
    } afterDelay:0.6];
    [self waitForExpectationsWithTimeout:0.8 handler:nil];

    OCMVerifyAll(self.tox);
}

- (void)testBootstrapDidConnectVerify
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"bootstrap"];

    OCMStub([self.settingsStorage bootstrapDidConnect]).andReturn(YES);

    self.submanager.didConnectDelay = 0.1;
    self.submanager.iterationTime = 0.05;

    [self.submanager addNodeWithIpv4Host:@"one" ipv6Host:nil udpPort:1 tcpPorts:@[] publicKey:@"1"];

    OCMExpect([self.tox bootstrapFromHost:@"one" port:1 publicKey:@"1" error:[OCMArg anyObjectRef]]);

    [self.submanager bootstrap];

    [self performBlock:^{
        [expectation fulfill];
    } afterDelay:0.3];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];

    OCMVerifyAll(self.tox);
}

- (void)testBootstrapDidConnectReject
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"bootstrap"];

    OCMStub([self.settingsStorage bootstrapDidConnect]).andReturn(YES);

    self.submanager.didConnectDelay = 0.2;
    self.submanager.iterationTime = 0.05;

    [self.submanager addNodeWithIpv4Host:@"one" ipv6Host:nil udpPort:1 tcpPorts:@[] publicKey:@"1"];

    [self.submanager bootstrap];

    [self performBlock:^{
        [expectation fulfill];
    } afterDelay:0.1];
    [self waitForExpectationsWithTimeout:0.15 handler:nil];

    OCMVerifyAll(self.tox);
}

- (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay
{
    [self performSelector:@selector(runBlock:) withObject:block afterDelay:delay];
}

- (void)runBlock:(void (^)())block
{
    block();
}

@end
