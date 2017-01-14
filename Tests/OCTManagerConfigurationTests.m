// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OCTManagerConfiguration.h"

@interface OCTManagerConfigurationTests : XCTestCase

@end

@implementation OCTManagerConfigurationTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDefaultConfiguration
{
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];

    XCTAssertNotNil(configuration.fileStorage);
    XCTAssertNotNil(configuration.options);
}

- (void)testCopy
{
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    configuration.options.ipv6Enabled = YES;
    configuration.options.udpEnabled = YES;
    configuration.options.localDiscoveryEnabled = YES;
    configuration.options.proxyType = OCTToxProxyTypeHTTP;
    configuration.options.proxyHost = @"proxy.address";
    configuration.options.proxyPort = 999;
    configuration.options.startPort = 123;
    configuration.options.endPort = 321;
    configuration.options.tcpPort = 777;
    configuration.options.holePunchingEnabled = YES;
    configuration.importToxSaveFromPath = @"save.tox";

    OCTManagerConfiguration *c2 = [configuration copy];

    configuration.options.ipv6Enabled = NO;
    configuration.options.udpEnabled = NO;
    configuration.options.localDiscoveryEnabled = NO;
    configuration.options.proxyType = OCTToxProxyTypeSocks5;
    configuration.options.proxyHost = @"another.address";
    configuration.options.proxyPort = 10;
    configuration.options.startPort = 11;
    configuration.options.endPort = 12;
    configuration.options.tcpPort = 13;
    configuration.options.holePunchingEnabled = NO;
    configuration.importToxSaveFromPath = @"another.tox";

    XCTAssertEqualObjects(configuration.fileStorage, c2.fileStorage);

    XCTAssertTrue(c2.options.ipv6Enabled);
    XCTAssertTrue(c2.options.udpEnabled);
    XCTAssertTrue(c2.options.localDiscoveryEnabled);
    XCTAssertEqual(c2.options.proxyType, OCTToxProxyTypeHTTP);
    XCTAssertEqualObjects(c2.options.proxyHost, @"proxy.address");
    XCTAssertEqual(c2.options.proxyPort, 999);
    XCTAssertEqual(c2.options.startPort, 123);
    XCTAssertEqual(c2.options.endPort, 321);
    XCTAssertEqual(c2.options.tcpPort, 777);
    XCTAssertTrue(c2.options.holePunchingEnabled);
    XCTAssertEqualObjects(c2.importToxSaveFromPath, @"save.tox");
}

@end
