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
    configuration.options.IPv6Enabled = YES;
    configuration.options.UDPEnabled = YES;
    configuration.options.proxyType = OCTToxProxyTypeHTTP;
    configuration.options.proxyHost = @"proxy.address";
    configuration.options.proxyPort = 999;
    configuration.options.tcpPort = 777;
    configuration.importToxSaveFromPath = @"save.tox";

    OCTManagerConfiguration *c2 = [configuration copy];

    XCTAssertEqualObjects(configuration.fileStorage, c2.fileStorage);

    XCTAssertEqual(configuration.options.IPv6Enabled, c2.options.IPv6Enabled);
    XCTAssertEqual(configuration.options.UDPEnabled, c2.options.UDPEnabled);
    XCTAssertEqual(configuration.options.proxyType, c2.options.proxyType);
    XCTAssertEqualObjects(configuration.options.proxyHost, c2.options.proxyHost);
    XCTAssertEqual(configuration.options.proxyPort, c2.options.proxyPort);
    XCTAssertEqual(configuration.options.tcpPort, c2.options.tcpPort);
    XCTAssertEqualObjects(configuration.importToxSaveFromPath, c2.importToxSaveFromPath);
}

@end
