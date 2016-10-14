// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
    OCTToxEncryptSave *save = [[OCTToxEncryptSave alloc] initWithPassphrase:@"p@s$" toxData:nil error:nil];

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

    save = nil;

    OCTToxEncryptSave *anotherSave = [[OCTToxEncryptSave alloc] initWithPassphrase:@"p@s$" toxData:encrypted error:nil];

    NSData *anotherDecrypted = [anotherSave decryptData:encrypted error:nil];

    XCTAssertFalse([OCTToxEncryptSave isDataEncrypted:anotherDecrypted]);
    XCTAssertTrue([data isEqualToData:anotherDecrypted]);
    XCTAssertFalse([encrypted isEqualToData:anotherDecrypted]);
}

@end
