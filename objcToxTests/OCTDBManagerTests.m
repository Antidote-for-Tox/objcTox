//
//  OCTDBManagerTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <Realm.h>
#import <XCTest/XCTest.h>

#import "OCTDBManager.h"
#import "OCTDBFriendRequest.h"

@interface OCTDBManager()

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) RLMRealm *realm;

@end

@interface OCTDBManagerTests : XCTestCase

@property (strong, nonatomic) OCTDBManager *manager;

@end

@implementation OCTDBManagerTests

- (NSString *)realmPath
{
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];

    return [directory stringByAppendingPathComponent:@"test.realm"];
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.manager = [[OCTDBManager alloc] initWithDatabasePath:[self realmPath]];
}

- (void)tearDown
{
    NSString *realmPath = [self realmPath];
    NSString *lockPath = [realmPath stringByAppendingString:@".lock"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:realmPath error:nil];
    [fileManager removeItemAtPath:lockPath error:nil];

    self.manager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.manager);
    XCTAssertNotNil(self.manager.queue);
    XCTAssertNotNil(self.manager.realm);
    XCTAssertEqualObjects(self.manager.realm.path, [self realmPath]);
}

- (void)testFriendRequests
{
    OCTDBFriendRequest *db1 = [OCTDBFriendRequest new];
    db1.publicKey = @"key1";
    db1.message = @"message1";

    OCTDBFriendRequest *db2 = [OCTDBFriendRequest new];
    db2.publicKey = @"key2";
    db2.message = @"message2";

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:db1];
    [self.manager.realm addObject:db2];
    [self.manager.realm commitWriteTransaction];

    NSArray *array = [self.manager friendRequests];

    XCTAssertEqual(array.count, 2);

    OCTFriendRequest *request1 = array[0];
    OCTFriendRequest *request2 = array[1];

    XCTAssertEqualObjects(db1.publicKey, request1.publicKey);
    XCTAssertEqualObjects(db1.message, request1.message);
    XCTAssertEqualObjects(db2.publicKey, request2.publicKey);
    XCTAssertEqualObjects(db2.message, request2.message);
}

- (void)testAddFriendRequest
{
    OCTFriendRequest *request = [OCTFriendRequest new];
    request.publicKey = @"key";
    request.message = @"message";

    [self.manager addFriendRequest:request];

    OCTDBFriendRequest *db = [OCTDBFriendRequest objectInRealm:self.manager.realm forPrimaryKey:request.publicKey];

    XCTAssertNotNil(db);
    XCTAssertEqualObjects(request.publicKey, db.publicKey);
    XCTAssertEqualObjects(request.message, db.message);
}

- (void)testRemoveFriendRequest
{
    OCTDBFriendRequest *db = [OCTDBFriendRequest new];
    db.publicKey = @"key";
    db.message = @"message";

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:db];
    [self.manager.realm commitWriteTransaction];

    OCTFriendRequest *request = [OCTFriendRequest new];
    request.publicKey = [db.publicKey copy];
    request.message = [db.message copy];

    [self.manager removeFriendRequest:request];

    OCTDBFriendRequest *removedDb = [OCTDBFriendRequest objectInRealm:self.manager.realm forPrimaryKey:request.publicKey];

    XCTAssertNil(removedDb);
}

@end
