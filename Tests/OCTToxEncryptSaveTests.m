//
//  OCTToxEncryptSaveTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 05/09/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCTToxEncryptSave.h"

@interface OCTToxEncryptSaveTests : XCTestCase

@end

@implementation OCTToxEncryptSaveTests

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

- (void)testClassMethods
{
    NSData *data = [@"data" dataUsingEncoding:NSUTF8StringEncoding];

    XCTAssertFalse([OCTToxEncryptSave isDataEncrypted:data]);

    NSData *encrypted = [OCTToxEncryptSave encryptData:data withPassphrase:@"password123" error:nil];

    XCTAssertTrue([OCTToxEncryptSave isDataEncrypted:encrypted]);
    XCTAssertFalse([data isEqualToData:encrypted]);

    NSData *decrypted = [OCTToxEncryptSave decryptData:encrypted withPassphrase:@"password123" error:nil];

    XCTAssertFalse([OCTToxEncryptSave isDataEncrypted:decrypted]);
    XCTAssertTrue([data isEqualToData:decrypted]);
    XCTAssertFalse([encrypted isEqualToData:decrypted]);
}

- (void)testInstanceMethods
{
    OCTToxEncryptSave *save = [[OCTToxEncryptSave alloc] initWithPassphrase:@"p@s$" error:nil];

    XCTAssertNotNil(save);

    NSData *data = [@"data" dataUsingEncoding:NSUTF8StringEncoding];

    XCTAssertFalse([OCTToxEncryptSave isDataEncrypted:data]);

    NSData *encrypted = [save encryptData:data error:nil];

    XCTAssertTrue([OCTToxEncryptSave isDataEncrypted:encrypted]);
    XCTAssertFalse([data isEqualToData:encrypted]);

    NSData *decrypted = [save decryptData:encrypted error:nil];

    XCTAssertFalse([OCTToxEncryptSave isDataEncrypted:decrypted]);
    XCTAssertTrue([data isEqualToData:decrypted]);
    XCTAssertFalse([encrypted isEqualToData:decrypted]);
}

@end
