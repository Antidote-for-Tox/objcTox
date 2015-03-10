//
//  OCTSubmanagerAvatarsTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "OCTSubmanagerAvatars.h"
#import "OCTFileStorageProtocol.h"

static NSString *const filePath = @"path/For/Avatars/Directory/user_avatar";

@interface OCTSubmanagerAvatarsTests : XCTestCase

@property (strong, nonatomic) OCTSubmanagerAvatars *subManagerAvatar;

@end

@implementation OCTSubmanagerAvatarsTests

- (void)setUp
{
    self.subManagerAvatar = [[OCTSubmanagerAvatars alloc] init];
    self.subManagerAvatar.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));

    id fileStorageMock = OCMProtocolMock(@protocol(OCTFileStorageProtocol));
    OCMStub([fileStorageMock pathForAvatarsDirectory]).andReturn(filePath);
    OCMStub([self.subManagerAvatar.dataSource managerGetFileStorage]).andReturn(fileStorageMock);

    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.subManagerAvatar = nil;
    [super tearDown];
}

- (void)testSetAvatar
{
    id mockFileManager = OCMClassMock([NSFileManager class]);
    OCMStub([mockFileManager defaultManager]).andReturn(mockFileManager);
    OCMStub([mockFileManager fileExistsAtPath:[OCMArg isNotNil]]).andReturn(YES);

    [self.subManagerAvatar setAvatar:nil];
    OCMVerify([mockFileManager removeItemAtPath:[OCMArg isNotNil] error:nil]);
}

- (void)testHasAvatar
{
    XCTAssertFalse([self.subManagerAvatar hasAvatar]);
}

@end
