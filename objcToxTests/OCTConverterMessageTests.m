//
//  OCTConverterMessageTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTConverterMessage.h"
#import "OCTMessageAbstract+Private.h"
#import "OCTMessageText+Private.h"
#import "OCTMessageFile+Private.h"
#import "OCTDBMessageAbstract.h"

@interface OCTConverterMessageTests : XCTestCase

@property (strong, nonatomic) OCTConverterMessage *converter;

@end

@implementation OCTConverterMessageTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.converter = [OCTConverterMessage new];
}

- (void)tearDown
{
    self.converter = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testObjectClassName
{
    XCTAssertEqualObjects([self.converter objectClassName], @"OCTMessageAbstract");
}

- (void)testObjectFromRLMObjectText
{
    OCTDBMessageAbstract *db = [OCTDBMessageAbstract new];
    db.dateInterval = [[NSDate date] timeIntervalSince1970];
    db.sender = [OCTDBFriend new];
    db.textMessage = [OCTDBMessageText new];
    db.textMessage.text = @"text";
    db.textMessage.isDelivered = YES;

    id friend = OCMClassMock([OCTFriend class]);
    id converterFriend = OCMClassMock([OCTConverterFriend class]);
    OCMStub([converterFriend objectFromRLMObject:db.sender]).andReturn(friend);

    self.converter.converterFriend = converterFriend;
    OCTMessageAbstract *message = (OCTMessageAbstract *)[self.converter objectFromRLMObject:db];

    XCTAssertTrue([message isKindOfClass:[OCTMessageText class]]);

    OCTMessageText *text = (OCTMessageText *)message;

    XCTAssertEqual(db.dateInterval, [text.date timeIntervalSince1970]);
    XCTAssertEqual(friend, text.sender);
    XCTAssertEqualObjects(db.textMessage.text, text.text);
    XCTAssertEqual(db.textMessage.isDelivered, text.isDelivered);
}

- (void)testObjectFromRLMObjectFile
{
    OCTDBMessageAbstract *db = [OCTDBMessageAbstract new];
    db.dateInterval = [[NSDate date] timeIntervalSince1970];
    db.sender = [OCTDBFriend new];
    db.fileMessage = [OCTDBMessageFile new];
    db.fileMessage.fileType = OCTMessageFileTypeReady;
    db.fileMessage.fileSize = 100;
    db.fileMessage.fileName = @"fileName";
    db.fileMessage.filePath = @"filePath";
    db.fileMessage.fileUTI = @"fileUTI";

    id friend = OCMClassMock([OCTFriend class]);
    id converterFriend = OCMClassMock([OCTConverterFriend class]);
    OCMStub([converterFriend objectFromRLMObject:db.sender]).andReturn(friend);

    self.converter.converterFriend = converterFriend;
    OCTMessageAbstract *message = (OCTMessageAbstract *)[self.converter objectFromRLMObject:db];

    XCTAssertTrue([message isKindOfClass:[OCTMessageFile class]]);

    OCTMessageFile *file = (OCTMessageFile *)message;

    XCTAssertEqual(db.dateInterval, [file.date timeIntervalSince1970]);
    XCTAssertEqual(friend, file.sender);
    XCTAssertEqual(db.fileMessage.fileType, file.fileType);
    XCTAssertEqual(db.fileMessage.fileSize, file.fileSize);
    XCTAssertEqualObjects(db.fileMessage.filePath, file.filePath);
    XCTAssertEqualObjects(db.fileMessage.filePath, file.filePath);
    XCTAssertEqualObjects(db.fileMessage.fileUTI, file.fileUTI);
}

- (void)testRlmSortDescriptorFromDescriptor
{
    OCTSortDescriptor *date = [OCTSortDescriptor sortDescriptorWithProperty:@"date" ascending:YES];

    RLMSortDescriptor *rlm1 = [self.converter rlmSortDescriptorFromDescriptor:date];

    XCTAssertEqualObjects(@"dateInterval", rlm1.property);
    XCTAssertEqual(date.ascending, rlm1.ascending);
}

@end
