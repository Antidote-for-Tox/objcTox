//
//  OCTFileToolsTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 17.04.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCTFileTools.h"

@interface OCTFileToolsTests : XCTestCase

@end

@implementation OCTFileToolsTests

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

- (void)testCreateNewFilePath
{
#define COMPARE(originalName, resultName) \
    XCTAssertEqualObjects([directory stringByAppendingPathComponent:resultName], \
                          [OCTFileTools createNewFilePathInDirectory:directory fileName:originalName]);

    NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"testCreateNewFilePath"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:directory error:nil];
    [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];

    COMPARE(@"file.txt", @"file.txt")
    COMPARE(@"file", @"file")

    [self createFileInDirectory : directory name : @"file.txt"];
    [self createFileInDirectory:directory name:@"file"];
    COMPARE(@"file.txt", @"file 2.txt")
    COMPARE(@"file", @"file 2")

    [self createFileInDirectory : directory name : @"file 2.txt"];
    [self createFileInDirectory:directory name:@"file 2"];
    COMPARE(@"file.txt", @"file 3.txt")
    COMPARE(@"file", @"file 3")

    [self createFileInDirectory : directory name : @"file 3.txt"];
    [self createFileInDirectory:directory name:@"file 3"];
    COMPARE(@"file.txt", @"file 4.txt")
    COMPARE(@"file", @"file 4")



    COMPARE(@"other 1.txt", @"other 1.txt")
    COMPARE(@"other 1", @"other 1")

    [self createFileInDirectory : directory name : @"other 1.txt"];
    [self createFileInDirectory:directory name:@"other 1"];
    COMPARE(@"other 1.txt", @"other 2.txt")
    COMPARE(@"other 1", @"other 2")

    [self createFileInDirectory : directory name : @"other 9.txt"];
    [self createFileInDirectory:directory name:@"other 9"];
    COMPARE(@"other 9.txt", @"other 10.txt")
    COMPARE(@"other 9", @"other 10")

    [self createFileInDirectory : directory name : @"other 10.txt"];
    [self createFileInDirectory:directory name:@"other 10"];
    COMPARE(@"other 9.txt", @"other 11.txt")
    COMPARE(@"other 9", @"other 11")



    COMPARE(@"qq 1q.txt", @"qq 1q.txt")
    COMPARE(@"qq 1q", @"qq 1q")

    [self createFileInDirectory : directory name : @"qq 1q.txt"];
    [self createFileInDirectory:directory name:@"qq 1q"];
    COMPARE(@"qq 1q.txt", @"qq 1q 2.txt")
    COMPARE(@"qq 1q", @"qq 1q 2")



    COMPARE(@"zz 0.txt", @"zz 0.txt")
    COMPARE(@"zz 0", @"zz 0")

    [self createFileInDirectory : directory name : @"zz 0.txt"];
    [self createFileInDirectory:directory name:@"zz 0"];
    COMPARE(@"zz 0.txt", @"zz 1.txt")
    COMPARE(@"zz 0", @"zz 1")

    [self createFileInDirectory : directory name : @"zz 1.txt"];
    [self createFileInDirectory:directory name:@"zz 1"];
    COMPARE(@"zz 0.txt", @"zz 2.txt")
    COMPARE(@"zz 0", @"zz 2")

    [self createFileInDirectory : directory name : @"zz -3.txt"];
    [self createFileInDirectory:directory name:@"zz -3"];
    COMPARE(@"zz -3.txt", @"zz -3 2.txt")
    COMPARE(@"zz -3", @"zz -3 2")



    COMPARE(@"1.txt", @"1.txt")
    COMPARE(@"1", @"1")

    [self createFileInDirectory : directory name : @"1.txt"];
    [self createFileInDirectory:directory name:@"1"];

    COMPARE(@"1.txt", @"1 2.txt")
    COMPARE(@"1", @"1 2")

    [fileManager removeItemAtPath : directory error : nil];
}

- (void)createFileInDirectory:(NSString *)directory name:(NSString *)name
{
    [[NSFileManager defaultManager] createFileAtPath:[directory stringByAppendingPathComponent:name]
                                            contents:[NSData data]
                                          attributes:nil];
}

@end
