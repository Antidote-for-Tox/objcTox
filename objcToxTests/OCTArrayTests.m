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
#import "OCTDBManager.h"

@interface OCTArray()

@property (strong, nonatomic) RLMResults *results;
@property (strong, nonatomic) id<OCTConverterProtocol> converter;

@end

@interface OCTArrayTests : XCTestCase

@property (strong, nonatomic) RLMResults *results;
@property (strong, nonatomic) id<OCTConverterProtocol> converter;
@property (strong, nonatomic) OCTArray *array;

@end

@implementation OCTArrayTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.results = OCMClassMock([RLMResults class]);
    self.converter = OCMProtocolMock(@protocol(OCTConverterProtocol));

    self.array = [[OCTArray alloc] initWithRLMResults:self.results converter:self.converter];
}

- (void)tearDown
{
    self.results = nil;
    self.converter = nil;

    self.array = nil;

    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.array);
    XCTAssertEqual(self.array.results, self.results);
    XCTAssertEqual(self.array.converter, self.converter);
}

- (void)testDelegate
{
    OCMStub([self.converter dbObjectClassName]).andReturn(@"NSString");

    id delegate = OCMProtocolMock(@protocol(OCTArrayDelegate));

    self.array.delegate = delegate;

    [[NSNotificationCenter defaultCenter] postNotificationName:kOCTDBManagerUpdateNotification
                                                        object:nil
                                                      userInfo:@{ kOCTDBManagerObjectClassKey : [NSString class]}];

    OCMVerify([delegate OCTArrayWasUpdated:self.array]);
}

- (void)testDelegateNoUpdate
{
    OCMStub([self.converter objectClassName]).andReturn(@"NSString");

    id delegate = OCMProtocolMock(@protocol(OCTArrayDelegate));
    [[delegate reject] OCTArrayWasUpdated:[OCMArg any]];

    self.array.delegate = delegate;

    [[NSNotificationCenter defaultCenter] postNotificationName:kOCTDBManagerUpdateNotification
                                                        object:nil
                                                      userInfo:@{ kOCTDBManagerObjectClassKey : [NSNumber class]}];
}

- (void)testCount
{
    OCMStub([self.results count]).andReturn(5);

    XCTAssertEqual(self.array.count, 5);
}

- (void)testObjectClassName
{
    OCMStub([self.converter objectClassName]).andReturn(@"name");

    XCTAssertEqualObjects(self.array.objectClassName, @"name");
}

- (void)testFirstObject
{
    id rlmObject = @"rlmObject";
    id object = @"object";

    OCMStub([self.results firstObject]).andReturn(rlmObject);
    OCMStub([self.converter objectFromRLMObject:rlmObject]).andReturn(object);

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
    OCMStub([self.converter objectFromRLMObject:rlmObject]).andReturn(object);

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

    OCMStub([self.converter rlmSortDescriptorFromDescriptor:(id)@"foo"]).andReturn(@"bar");
    OCMStub([self.converter rlmSortDescriptorFromDescriptor:(id)@"foo2"]).andReturn(@"bar2");

    NSArray *rlmDescriptors = @[ @"bar", @"bar2" ];
    OCMExpect([self.results sortedResultsUsingDescriptors:rlmDescriptors]).andReturn(results);

    OCTArray *array = [self.array sortedObjectsUsingDescriptors:@[ @"foo", @"foo2" ]];

    XCTAssertNotNil(array);
    XCTAssertEqual(results, array.results);
    XCTAssertEqual(self.array.converter, array.converter);
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

    OCMStub([self.converter objectFromRLMObject:rlmObj0]).andReturn(obj0);
    OCMStub([self.converter objectFromRLMObject:rlmObj1]).andReturn(obj1);
    OCMStub([self.converter objectFromRLMObject:rlmObj2]).andReturn(obj2);

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
