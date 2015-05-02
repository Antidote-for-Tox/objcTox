//
//  OCTConverterFriendRequestTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OCTConverterFriendRequest.h"
#import "OCTFriendRequest.h"
#import "OCTDBFriendRequest.h"

@interface OCTConverterFriendRequestTests : XCTestCase

@property (strong, nonatomic) OCTConverterFriendRequest *converter;

@end

@implementation OCTConverterFriendRequestTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.converter = [OCTConverterFriendRequest new];
}

- (void)tearDown
{
    self.converter = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testObjectClassName
{
    XCTAssertEqualObjects([self.converter objectClassName], @"OCTFriendRequest");
}

- (void)testObjectFromRLMObject
{
    OCTDBFriendRequest *db = [OCTDBFriendRequest new];
    db.publicKey = @"key";
    db.message = @"message";

    OCTFriendRequest *request = (OCTFriendRequest *)[self.converter objectFromRLMObject:db];

    XCTAssertNotNil(request);
    XCTAssertEqual(db.publicKey, request.publicKey);
    XCTAssertEqual(db.message, request.message);
}

- (void)testRlmObjectFromObject
{
    OCTFriendRequest *request = [OCTFriendRequest new];
    request.publicKey = @"key";
    request.message = @"message";

    OCTDBFriendRequest *db = (OCTDBFriendRequest *)[self.converter rlmObjectFromObject:request];

    XCTAssertNotNil(db);
    XCTAssertEqual(db.publicKey, request.publicKey);
    XCTAssertEqual(db.message, request.message);
}

- (void)testRlmSortDescriptorFromDescriptor
{
    OCTSortDescriptor *descriptor1 = [OCTSortDescriptor sortDescriptorWithProperty:@"publicKey" ascending:NO];
    OCTSortDescriptor *descriptor2 = [OCTSortDescriptor sortDescriptorWithProperty:@"message" ascending:YES];

    RLMSortDescriptor *rlm1 = [self.converter rlmSortDescriptorFromDescriptor:descriptor1];
    RLMSortDescriptor *rlm2 = [self.converter rlmSortDescriptorFromDescriptor:descriptor2];

    XCTAssertEqualObjects(descriptor1.property, rlm1.property);
    XCTAssertEqual(descriptor1.ascending, rlm1.ascending);
    XCTAssertEqualObjects(descriptor2.property, rlm2.property);
    XCTAssertEqual(descriptor2.ascending, rlm2.ascending);
}

@end
