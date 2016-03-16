//
//  OCTFileDownloadOperation.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileDownloadOperation.h"
#import "OCTLogging.h"

static const OCTToxFileSize kCacheSize = 100 * 1024;

@interface OCTFileDownloadOperation ()

@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSFileHandle *handle;

@property (strong, nonatomic) NSMutableData *cache;

@end

@implementation OCTFileDownloadOperation

#pragma mark -  Public

- (void)receiveChunk:(NSData *)chunk position:(OCTToxFileSize)position
{
    if (! chunk) {
        [self.handle writeData:self.cache];
        [self finishWithSuccess];
        return;
    }

    if (self.bytesDone != position) {
        [self.tox fileSendControlForFileNumber:self.fileNumber
                                  friendNumber:self.friendNumber
                                       control:OCTToxFileControlCancel
                                         error:nil];
        [self finishWithError:nil];
        return;
    }

    if (! self.cache) {
        self.cache = [NSMutableData new];
    }
    [self.cache appendData:chunk];

    if (self.cache.length > kCacheSize) {
        [self.handle writeData:self.cache];
        self.cache = nil;
    }

    self.bytesDone += chunk.length;
}

#pragma mark -  Override

- (void)operationStarted
{
    [super operationStarted];
    NSError *error;

    NSString *path = [self createNewFile:&error];

    if (! path) {
        [self finishWithError:error];
        return;
    }

    self.handle = [NSFileHandle fileHandleForWritingAtPath:path];
    NSAssert(self.handle, @"Cannot open file handle");

    if (! [self.tox fileSendControlForFileNumber:self.fileNumber
                                    friendNumber:self.friendNumber
                                         control:OCTToxFileControlResume
                                           error:&error]) {
        [self finishWithError:error];
        return;
    }
}

#pragma mark -  Private

- (NSString *)createNewFile:(NSError **)error
{
    NSString *path = [self.fileStorage.pathForTemporaryFilesDirectory stringByAppendingPathComponent:self.operationId];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    OCTLogInfo(@"saving to path %@", path);

    if ([fileManager fileExistsAtPath:path]) {
        OCTLogWarn(@"file already exist, removing it");

        if (! [fileManager removeItemAtPath:path error:error]) {
            return nil;
        }
    }

    if (! [fileManager createFileAtPath:path contents:nil attributes:nil]) {
        return nil;
    }

    return path;
}

@end
