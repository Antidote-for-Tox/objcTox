//
//  OCTDBMessageTextTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import <Realm/Realm.h>

#import "OCTDBMessageText.h"
#import "OCTMessageText+Private.h"
#import "OCTMessageAbstract+Private.h"
#import "OCTFriend+Private.h"

@interface OCTDBMessageTextTests : XCTestCase

@end

@implementation OCTDBMessageTextTests

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
    OCTMessageText *message = [OCTMessageText new];
    message.text = @"text";
    message.isDelivered = YES;
    message.type = OCTToxMessageTypeAction;

    OCTDBMessageText *db = [[OCTDBMessageText alloc] initWithMessageText:message];

    XCTAssertNotNil(db);
    XCTAssertEqualObjects(db.text, message.text);
    XCTAssertEqual(db.isDelivered, message.isDelivered);
    XCTAssertEqual(db.type, message.type);
}

@end
