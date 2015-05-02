//
//  OCTArrayTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTArray.h"
#import "OCTArray+Private.h"

@interface OCTArray()

@property (strong, nonatomic) RLMResults *results;
@property (strong, nonatomic) id<OCTConvertorProtocol> convertor;

@end

@interface OCTArrayTests : XCTestCase

@property (strong, nonatomic) RLMResults *results;
@property (strong, nonatomic) id<OCTConvertorProtocol> convertor;
@property (strong, nonatomic) OCTArray *array;

@end

@implementation OCTArrayTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.results = OCMClassMock([RLMResults class]);
    self.convertor = OCMProtocolMock(@protocol(OCTConvertorProtocol));

    self.array = [[OCTArray alloc] initWithRLMResults:self.results convertor:self.convertor];
}

- (void)tearDown
{
    self.results = nil;
    self.convertor = nil;

    self.array = nil;

    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.array);
    XCTAssertEqual(self.array.results, self.results);
    XCTAssertEqual(self.array.convertor, self.convertor);
}

- (void)testCount
{
    OCMStub([self.results count]).andReturn(5);

    XCTAssertEqual(self.array.count, 5);
}

- (void)testObjectClassName
{
    OCMStub([self.convertor objectClassName]).andReturn(@"name");

    XCTAssertEqualObjects(self.array.objectClassName, @"name");
}

- (void)testFirstObject
{
    id rlmObject = @"rlmObject";
    id object = @"object";

    OCMStub([self.results firstObject]).andReturn(rlmObject);
    OCMStub([self.convertor objectFromRLMObject:rlmObject]).andReturn(object);

    XCTAssertEqualObjects([self.array firstObject], object);
}

- (void)testFirstObjectNil
{
    OCMStub([self.results firstObject]).andReturn(nil);

    XCTAssertNil([self.array firstObject]);
}

- (void)testLastObject
{
    id rlmObject = @"rlmObject";
    id object = @"object";

    OCMStub([self.results lastObject]).andReturn(rlmObject);
    OCMStub([self.convertor objectFromRLMObject:rlmObject]).andReturn(object);

    XCTAssertEqualObjects([self.array lastObject], object);
}

- (void)testLastObjectNil
{
    OCMStub([self.results lastObject]).andReturn(nil);

    XCTAssertNil([self.array lastObject]);
}

- (void)testSortedObjectsUsingDescriptors
{
    id results = OCMClassMock([RLMResults class]);

    OCMStub([self.convertor rlmSortDescriptorFromDescriptor:(id)@"foo"]).andReturn(@"bar");
    OCMStub([self.convertor rlmSortDescriptorFromDescriptor:(id)@"foo2"]).andReturn(@"bar2");

    NSArray *rlmDescriptors = @[ @"bar", @"bar2" ];
    OCMExpect([self.results sortedResultsUsingDescriptors:rlmDescriptors]).andReturn(results);

    OCTArray *array = [self.array sortedObjectsUsingDescriptors:@[ @"foo", @"foo2" ]];

    XCTAssertNotNil(array);
    XCTAssertEqual(results, array.results);
    XCTAssertEqual(self.array.convertor, array.convertor);
    OCMVerify((id)self.results);
}

- (void)testEnumerateObjectsUsingBlock
{
    id rlmObj0 = OCMClassMock([NSString class]);
    id rlmObj1 = OCMClassMock([NSString class]);
    id rlmObj2 = OCMClassMock([NSString class]);

    id obj0 = OCMClassMock([NSString class]);
    id obj1 = OCMClassMock([NSString class]);
    // obj2 should not receive any messages
    id obj2 = OCMStrictClassMock([NSString class]);

    OCMStub([self.results count]).andReturn(3);
    OCMStub([self.results objectAtIndex:0]).andReturn(rlmObj0);
    OCMStub([self.results objectAtIndex:1]).andReturn(rlmObj1);
    OCMStub([self.results objectAtIndex:2]).andReturn(rlmObj2);

    OCMStub([self.convertor objectFromRLMObject:rlmObj0]).andReturn(obj0);
    OCMStub([self.convertor objectFromRLMObject:rlmObj1]).andReturn(obj1);
    OCMStub([self.convertor objectFromRLMObject:rlmObj2]).andReturn(obj2);

    [self.array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj copy];

        if (idx == 1) {
            *stop = YES;
        }
    }];

    OCMVerify([obj0 copy]);
    OCMVerify([obj1 copy]);
}

@end
