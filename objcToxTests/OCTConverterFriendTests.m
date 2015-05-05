//
//  OCTConverterFriendTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTConverterFriend.h"
#import "OCTFriend+Private.h"
#import "OCTDBFriend.h"

@interface OCTConverterFriendTests : XCTestCase

@property (strong, nonatomic) OCTConverterFriend *converter;

@end

@implementation OCTConverterFriendTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.converter = [OCTConverterFriend new];
}

- (void)tearDown
{
    self.converter = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testObjectClassName
{
    XCTAssertEqualObjects([self.converter objectClassName], @"OCTFriend");
}

- (void)testObjectFromRLMObject
{
    OCTDBFriend *db = [OCTDBFriend new];
    db.friendNumber = 5;

    id friend = OCMClassMock([OCTFriend class]);

    id dataSource = OCMProtocolMock(@protocol(OCTConverterFriendDataSource));
    OCMStub([dataSource friendWithFriendNumber:5]).andReturn(friend);
    self.converter.dataSource = dataSource;

    OCTFriend *theFriend = (OCTFriend *)[self.converter objectFromRLMObject:db];

    XCTAssertNotNil(theFriend);
    XCTAssertEqual(friend, theFriend);
}

- (void)testRlmObjectFromObject
{
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 5;

    OCTDBFriend *db = (OCTDBFriend *)[self.converter rlmObjectFromObject:friend];

    XCTAssertNotNil(db);
    XCTAssertEqual(db.friendNumber, 5);
}

- (void)testRlmSortDescriptorFromDescriptor
{
    OCTSortDescriptor *friendNumber = [OCTSortDescriptor sortDescriptorWithProperty:@"friendNumber" ascending:YES];
    OCTSortDescriptor *name = [OCTSortDescriptor sortDescriptorWithProperty:@"name" ascending:YES];

    RLMSortDescriptor *rlm1 = [self.converter rlmSortDescriptorFromDescriptor:friendNumber];
    RLMSortDescriptor *rlm2 = [self.converter rlmSortDescriptorFromDescriptor:name];

    XCTAssertEqualObjects(friendNumber.property, rlm1.property);
    XCTAssertEqual(friendNumber.ascending, rlm1.ascending);
    XCTAssertNil(rlm2);
}

@end
