//
//  OCTDBMessageFileTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTDBMessageFile.h"
#import "OCTMessageFile+Private.h"
#import "OCTMessageAbstract+Private.h"
#import "OCTFriend+Private.h"
#import "RLMRealm.h"

@interface OCTDBMessageFileTests : XCTestCase

@end

@implementation OCTDBMessageFileTests

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
    OCTMessageFile *message = [OCTMessageFile new];
    message.fileType = OCTMessageFileTypeLoading;
    message.fileSize = 123;
    message.fileName = @"fileName";
    message.filePath = @"filePath";
    message.fileUTI = @"fileUTI";

    OCTDBMessageFile *db = [[OCTDBMessageFile alloc] initWithMessageFile:message];

    XCTAssertNotNil(db);
    XCTAssertEqual(db.fileType, message.fileType);
    XCTAssertEqual(db.fileSize, message.fileSize);
    XCTAssertEqualObjects(db.fileName, message.fileName);
    XCTAssertEqualObjects(db.filePath, message.filePath);
    XCTAssertEqualObjects(db.fileUTI, message.fileUTI);
}

- (void)textFillMessage
{
    OCTDBMessageFile *db = [OCTDBMessageFile new];
    db.fileType = 2;
    db.fileSize = 123;
    db.fileName = @"fileName";
    db.filePath = @"filePath";
    db.fileUTI = @"fileUTI";

    OCTMessageFile *message = [OCTMessageFile new];
    [db fillMessage:message];

    XCTAssertNotNil(message);
    XCTAssertEqual(db.fileType, message.fileType);
    XCTAssertEqual(db.fileSize, message.fileSize);
    XCTAssertEqualObjects(db.fileName, message.fileName);
    XCTAssertEqualObjects(db.filePath, message.filePath);
    XCTAssertEqualObjects(db.fileUTI, message.fileUTI);
}

@end
