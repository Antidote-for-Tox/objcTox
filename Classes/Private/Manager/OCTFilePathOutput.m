//
//  OCTFilePathOutput.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 21.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFilePathOutput.h"
#import "OCTLogging.h"

@interface OCTFilePathOutput ()

@property (copy, nonatomic, readonly, nonnull) NSString *tempFilePath;

@property (strong, nonatomic) NSFileHandle *handle;

@end

@implementation OCTFilePathOutput

#pragma mark -  Lifecycle

- (nullable instancetype)initWithTempFolder:(nonnull NSString *)tempFolder resultFolder:(nonnull NSString *)resultFolder
{
    self = [super init];

    if (! self) {
        return nil;
    }

    NSString *fileName = [[NSUUID UUID] UUIDString];

    _tempFilePath = [tempFolder stringByAppendingPathComponent:fileName];
    _resultFilePath = [resultFolder stringByAppendingPathComponent:fileName];

    OCTLogInfo(@"temp path %@", _tempFilePath);
    OCTLogInfo(@"result path %@", _resultFilePath);

    return self;
}

#pragma mark -  OCTFileOutputProtocol

- (BOOL)prepareToWrite
{
    if (! [[NSFileManager defaultManager] createFileAtPath:self.tempFilePath contents:nil attributes:nil]) {
        return NO;
    }

    self.handle = [NSFileHandle fileHandleForWritingAtPath:self.tempFilePath];

    if (! self.handle) {
        return NO;
    }

    return YES;
}

- (BOOL)writeData:(nonnull NSData *)data
{
    @try {
        [self.handle writeData:data];
        return YES;
    }
    @catch (NSException *ex) {
        OCTLogWarn(@"catched exception %@", ex);
    }

    return NO;
}

- (BOOL)finishWriting
{
    @try {
        [self.handle synchronizeFile];
    }
    @catch (NSException *ex) {
        OCTLogWarn(@"catched exception %@", ex);
        return NO;
    }

    return [[NSFileManager defaultManager] moveItemAtPath:self.tempFilePath toPath:self.resultFilePath error:nil];
}

- (void)cancel
{
    self.handle = nil;

    [[NSFileManager defaultManager] removeItemAtPath:self.tempFilePath error:nil];
}

@end
