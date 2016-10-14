// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OCTDefaultFileStorage.h"

@interface OCTDefaultFileStorageTests : XCTestCase

@end

@implementation OCTDefaultFileStorageTests

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

- (void)testProperties
{
    OCTDefaultFileStorage *storage = [[OCTDefaultFileStorage alloc] initWithBaseDirectory:@"/base"
                                                                       temporaryDirectory:@"/temp"];

    XCTAssertEqualObjects(storage.pathForToxSaveFile, @"/base/save.tox");
    XCTAssertEqualObjects(storage.pathForDatabase, @"/base/database");
    XCTAssertEqualObjects(storage.pathForDatabaseEncryptionKey, @"/base/database.encryptionkey");
    XCTAssertEqualObjects(storage.pathForDownloadedFilesDirectory, @"/base/files");
    XCTAssertEqualObjects(storage.pathForTemporaryFilesDirectory, @"/temp");
}

- (void)testCustomToxSaveFileName
{
    OCTDefaultFileStorage *storage = [[OCTDefaultFileStorage alloc] initWithToxSaveFileName:@"filename"
                                                                              baseDirectory:@"/base"
                                                                         temporaryDirectory:@"/temp"];

    XCTAssertEqualObjects(storage.pathForToxSaveFile, @"/base/filename.tox");
}

@end
