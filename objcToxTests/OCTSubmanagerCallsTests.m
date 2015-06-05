//
//  OCTSubmanagerCallsTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/4/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCTSubmanagerCalls+Private.h"
#import "OCTToxAV.h"
#import "OCTTox.h"

@interface OCTSubmanagerCalls (Tests)

@property (strong, nonatomic) OCTToxAV *toxAV;

@end

@interface OCTSubmanagerCallsTests : XCTestCase

@property (strong, nonatomic) OCTTox *tox;
@property (strong, nonatomic) OCTSubmanagerCalls *callManager;

@end

@implementation OCTSubmanagerCallsTests

- (void)setUp
{
    [super setUp];

    self.tox = [[OCTTox alloc] initWithOptions:[OCTToxOptions new] savedData:nil error:nil];
    self.callManager = [[OCTSubmanagerCalls alloc] initWithTox:self.tox];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.callManager = nil;
    self.tox = nil;
    [super tearDown];
}

@end
