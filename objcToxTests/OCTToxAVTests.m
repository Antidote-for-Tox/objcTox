//
//  OCTToxAVTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/2/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OCTToxAV.h"
#import "OCTTox+Private.h"
#import "toxav.h"

@interface OCTToxAV (Tests)

- (void)fillError:(NSError **)error withCErrorInit:(TOXAV_ERR_NEW)cError;

@end
@interface OCTToxAVTests : XCTestCase

@property (strong, nonatomic) OCTToxAV *toxAV;

@end

@implementation OCTToxAVTests

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


- (void)testFillErrorInit
{

}

@end
