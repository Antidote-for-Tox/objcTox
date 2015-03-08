//
//  OCTSubmanagerAvatarsTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "OCTSubmanagerAvatars.h"

@interface OCTSubmanagerAvatars(Tests)

@property OCTTox *tox;

@end


@interface OCTSubmanagerAvatarsTests : XCTestCase

@end

@implementation OCTSubmanagerAvatarsTests

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
    id fakeTox = [OCMArg any];

    OCTSubmanagerAvatars *avatars = [[OCTSubmanagerAvatars alloc] initWithTox:fakeTox];

    XCTAssertEqualObjects(avatars.tox, fakeTox);
}

@end
