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
- (void)fillError:(NSError **)error withCErrorCall:(TOXAV_ERR_CALL)cError;

@end
@interface OCTToxAVTests : XCTestCase

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTTox *tox;

@end

@implementation OCTToxAVTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.tox = [[OCTTox alloc] initWithOptions:[OCTToxOptions new] savedData:nil error:nil];
    self.toxAV = [[OCTToxAV alloc] initWithTox:self.tox error:nil];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.tox = nil;
    self.toxAV = nil;
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.toxAV);
}

- (void)testFillErrorInit
{
    [self.toxAV fillError:nil withCErrorInit:TOXAV_ERR_NEW_NULL];

    NSError *error;
    [self.toxAV fillError:&error withCErrorInit:TOXAV_ERR_NEW_NULL];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorInitNULL);

    error = nil;
    [self.toxAV fillError:&error withCErrorInit:TOXAV_ERR_NEW_MULTIPLE];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorInitMultiple);

    error = nil;
    [self.toxAV fillError:&error withCErrorInit:TOXAV_ERR_NEW_MALLOC];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorInitCodeMemoryError);

    error = nil;
    [self.toxAV fillError:&error withCErrorInit:TOXAV_ERR_NEW_MULTIPLE];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorInitMultiple);

}

- (void)testFillErrorCall
{
    [self.toxAV fillError:nil withCErrorCall:TOXAV_ERR_CALL_MALLOC];

    NSError *error;
    [self.toxAV fillError:&error withCErrorCall:TOXAV_ERR_CALL_MALLOC];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorCallMalloc);

    error = nil;
    [self.toxAV fillError:&error withCErrorCall:TOXAV_ERR_CALL_FRIEND_NOT_FOUND];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorCallFriendNotFound);

    error = nil;
    [self.toxAV fillError:&error withCErrorCall:TOXAV_ERR_CALL_FRIEND_NOT_CONNECTED];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorCallFriendNotConnected);

    error = nil;
    [self.toxAV fillError:&error withCErrorCall:TOXAV_ERR_CALL_FRIEND_ALREADY_IN_CALL];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorCallAlreadyInCall);

    error = nil;
    [self.toxAV fillError:&error withCErrorCall:TOXAV_ERR_CALL_INVALID_BIT_RATE];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorCallInvalidBitRate);
}

@end
