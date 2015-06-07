//
//  OCTCallTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/7/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OCTCall+Private.h"

@interface OCTCallTests : XCTestCase

@end

@implementation OCTCallTests

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
    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [[OCTFriend alloc] init];
    OCTCall *call = [[OCTCall alloc] initWithChat:chat friend:friend];

    XCTAssertNotNil(call);
    XCTAssertEqualObjects(call.chatSession, chat);
    XCTAssertEqualObjects(call.caller, friend);
    XCTAssertEqual(call.status, OCTCallStatusInactive);
}

@end
