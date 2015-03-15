//
//  OCTManagerTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OCTManager.h"
#import "OCTTox.h"
#import "OCTSubmanagerDataSource.h"

@interface OCTManager(Tests) <OCTSubmanagerDataSource>

@property (strong, nonatomic, readonly) OCTTox *tox;
@property (copy, nonatomic, readonly) OCTManagerConfiguration *configuration;

@end

@interface OCTManagerTests : XCTestCase

@end

@implementation OCTManagerTests

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

- (void)testInit
{
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];

    OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration];

    XCTAssertNotNil(manager);
    XCTAssertNotNil(manager.friends);
    XCTAssertNotNil(manager.avatars);
    XCTAssertNotNil(manager.tox);
    XCTAssertNotNil(manager.configuration);
}

- (void)testSubmanagerDataSource
{
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];

    OCTManager *manager = [[OCTManager alloc] initWithConfiguration:configuration];

    XCTAssertNotNil([manager managerGetTox]);
    XCTAssertNotNil([manager managerGetSettingsStorage]);
    XCTAssertNotNil([manager managerGetFileStorage]);
}

@end
