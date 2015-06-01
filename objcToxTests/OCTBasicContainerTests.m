//
//  OCTBasicContainerTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTBasicContainer.h"
#import "OCTManagerConstants.h"

@interface OCTBasicContainer (Tests)
@property (strong, nonatomic) NSMutableArray *array;
@property (strong, nonatomic) NSString *updateNotificationName;
@end

@interface OCTBasicContainerTests : XCTestCase

@property (strong, nonatomic) OCTBasicContainer *container;

@end

@implementation OCTBasicContainerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.container = [[OCTBasicContainer alloc] initWithObjects:nil updateNotificationName:nil];
}

- (void)tearDown
{
    self.container = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    id object = @1;
    NSString *notification = @"notification";

    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ object ]
                                                       updateNotificationName      :notification];

    XCTAssertTrue(container.array.count == 1);

    id theFriend = [container.array lastObject];
    XCTAssertEqual(object, theFriend);
    XCTAssertEqual(notification, container.updateNotificationName);
}

- (void)testSetComparator
{
    [self.container addObject:@4];
    [self.container addObject:@0];
    [self.container addObject:@1];
    [self.container addObject:@3];
    [self.container addObject:@2];
    [self.container addObject:@5];

    [self.container setComparatorForCurrentSort:^NSComparisonResult (NSNumber *first, NSNumber *second) {
        return [first compare:second];
    } sendNotification:NO];

    XCTAssertEqual([self.container objectAtIndex:0], @0);
    XCTAssertEqual([self.container objectAtIndex:1], @1);
    XCTAssertEqual([self.container objectAtIndex:2], @2);
    XCTAssertEqual([self.container objectAtIndex:3], @3);
    XCTAssertEqual([self.container objectAtIndex:4], @4);
    XCTAssertEqual([self.container objectAtIndex:5], @5);
}

- (void)testCount
{
    XCTAssertEqual([self.container count], 0);

    [self.container addObject:@1];
    [self.container addObject:@2];

    XCTAssertEqual([self.container count], 2);
}

- (void)testObjectAtIndex
{
    self.container.array = [NSMutableArray arrayWithArray:@[ @0, @1 ]];

    XCTAssertEqual([self.container objectAtIndex:0], @0);
    XCTAssertEqual([self.container objectAtIndex:1], @1);
    XCTAssertNil([self.container objectAtIndex:2]);
}

- (void)testUpdateNotificationForSetComparator
{
    BOOL (^checkBlock)(NSDictionary *) = ^BOOL (NSDictionary *userInfo) {
        XCTAssertTrue([userInfo isKindOfClass:[NSDictionary class]]);
        XCTAssertEqual(userInfo.count, 1);

        NSIndexSet *set = userInfo[kOCTContainerUpdateKeyUpdatedSet];
        XCTAssertEqual(set.count, 2);
        XCTAssertTrue([set containsIndex:0]);
        XCTAssertTrue([set containsIndex:1]);

        return YES;
    };

    id center = OCMClassMock([NSNotificationCenter class]);
    OCMStub([center defaultCenter]).andReturn(center);
    OCMExpect([center postNotificationName:@"notification" object:nil userInfo:[OCMArg checkWithBlock:checkBlock]]);

    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ @1, @0 ]
                                                       updateNotificationName      :@"notification"];
    [container setComparatorForCurrentSort:^NSComparisonResult (NSNumber *first, NSNumber *second) {
        return [first compare:second];
    } sendNotification:YES];

    OCMVerifyAll(center);
}

- (void)testUpdateNotificationForSetComparatorNoNotification
{
    id center = OCMClassMock([NSNotificationCenter class]);
    OCMStub([center defaultCenter]).andReturn(center);
    [[center reject] postNotificationName:@"notification" object:nil userInfo:[OCMArg any]];

    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ @1, @0 ]
                                                       updateNotificationName      :@"notification"];
    [container setComparatorForCurrentSort:^NSComparisonResult (NSNumber *first, NSNumber *second) {
        return [first compare:second];
    } sendNotification:NO];

    OCMVerifyAll(center);
}

- (void)testUpdateNotificationForAddObject
{
    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ @0 ]
                                                       updateNotificationName      :@"notification"];

    BOOL (^checkBlock)(NSDictionary *) = ^BOOL (NSDictionary *userInfo) {
        XCTAssertTrue([userInfo isKindOfClass:[NSDictionary class]]);
        XCTAssertEqual(userInfo.count, 1);

        NSIndexSet *set = userInfo[kOCTContainerUpdateKeyInsertedSet];
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:1]);

        return YES;
    };

    id center = OCMClassMock([NSNotificationCenter class]);
    OCMStub([center defaultCenter]).andReturn(center);
    OCMExpect([center postNotificationName:@"notification" object:nil userInfo:[OCMArg checkWithBlock:checkBlock]]);

    [container addObject:@1];

    OCMVerifyAll(center);
}

- (void)testUpdateNotificationForAddObjectWithSort
{
    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ @1 ]
                                                       updateNotificationName      :@"notification"];
    [container setComparatorForCurrentSort:^NSComparisonResult (NSNumber *first, NSNumber *second) {
        return [first compare:second];
    } sendNotification:NO];

    BOOL (^checkBlock)(NSDictionary *) = ^BOOL (NSDictionary *userInfo) {
        XCTAssertTrue([userInfo isKindOfClass:[NSDictionary class]]);
        XCTAssertEqual(userInfo.count, 1);

        NSIndexSet *set = userInfo[kOCTContainerUpdateKeyInsertedSet];
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:0]);

        return YES;
    };

    id center = OCMClassMock([NSNotificationCenter class]);
    OCMStub([center defaultCenter]).andReturn(center);
    OCMExpect([center postNotificationName:@"notification" object:nil userInfo:[OCMArg checkWithBlock:checkBlock]]);

    [container addObject:@0];

    OCMVerifyAll(center);
}

- (void)testUpdateNotificationForRemoveObject
{
    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ @0, @1 ]
                                                       updateNotificationName      :@"notification"];

    BOOL (^checkBlock)(NSDictionary *) = ^BOOL (NSDictionary *userInfo) {
        XCTAssertTrue([userInfo isKindOfClass:[NSDictionary class]]);
        XCTAssertEqual(userInfo.count, 1);

        NSIndexSet *set = userInfo[kOCTContainerUpdateKeyRemovedSet];
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:1]);

        return YES;
    };

    id center = OCMClassMock([NSNotificationCenter class]);
    OCMStub([center defaultCenter]).andReturn(center);
    OCMExpect([center postNotificationName:@"notification" object:nil userInfo:[OCMArg checkWithBlock:checkBlock]]);

    [container removeObject:@1];

    OCMVerifyAll(center);
}

- (void)testUpdateFriendsNotificationForUpdateFriend
{
    __block BOOL reverseSort = NO;
    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ @0, @1 ]
                                                       updateNotificationName      :@"notification"];
    [container setComparatorForCurrentSort:^NSComparisonResult (NSNumber *first, NSNumber *second) {
        return reverseSort ? [second compare : first] :[first compare:second];
    } sendNotification:NO];

    BOOL (^checkBlock)(NSDictionary *) = ^BOOL (NSDictionary *userInfo) {
        XCTAssertTrue([userInfo isKindOfClass:[NSDictionary class]]);
        XCTAssertEqual(userInfo.count, 2);

        NSIndexSet *set = userInfo[kOCTContainerUpdateKeyRemovedSet];
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:0]);

        set = userInfo[kOCTContainerUpdateKeyInsertedSet];
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:1]);

        return YES;
    };

    id center = OCMClassMock([NSNotificationCenter class]);
    OCMStub([center defaultCenter]).andReturn(center);
    OCMExpect([center postNotificationName:@"notification" object:nil userInfo:[OCMArg checkWithBlock:checkBlock]]);

    [container updateObjectPassingTest:^BOOL (NSNumber *obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqualToNumber:@0];
    } updateBlock:^(id obj) {
        reverseSort = YES;
    }];

    OCMVerifyAll(center);
}

- (void)testAddObject
{
    id object = @1;

    [self.container addObject:object];

    XCTAssertTrue(self.container.array.count == 1);

    id theObject = [self.container.array lastObject];
    XCTAssertEqual(object, theObject);

    XCTAssertThrowsSpecificNamed([self.container addObject:nil], NSException, NSInternalInconsistencyException);
    // trying to add save object twice
    XCTAssertThrowsSpecificNamed([self.container addObject:object], NSException, NSInternalInconsistencyException);
}

- (void)testRemoveObject
{
    id object = @1;

    [self.container addObject:object];
    [self.container removeObject:object];

    XCTAssertTrue(self.container.array.count == 0);

    XCTAssertThrowsSpecificNamed([self.container removeObject:nil], NSException, NSInternalInconsistencyException);
    // object not found
    XCTAssertThrowsSpecificNamed([self.container removeObject:object], NSException, NSInternalInconsistencyException);
}

- (void)testUpdateObject
{
    id object = @1;

    [self.container addObject:object];

    id testBlock = ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
        return YES;
    };

    __block BOOL blockCalled = NO;
    [self.container updateObjectPassingTest:testBlock updateBlock:^(id obj) {
        blockCalled = YES;
        XCTAssertEqual(obj, object);
    }];

    XCTAssertTrue(blockCalled);

    XCTAssertThrowsSpecificNamed(
        [self.container updateObjectPassingTest:testBlock updateBlock:nil],
        NSException,
        NSInternalInconsistencyException
    );

    XCTAssertThrowsSpecificNamed(
        [self.container updateObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
        return NO;
    } updateBlock:^(id obj) { }],
        NSException,
        NSInternalInconsistencyException
    );
}

@end
