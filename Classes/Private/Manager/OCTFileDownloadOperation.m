//
//  OCTFileDownloadOperation.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileDownloadOperation.h"
#import "OCTFileBaseOperation+Private.h"
#import "OCTLogging.h"

@interface OCTFileDownloadOperation ()

@property (strong, nonatomic, readonly) NSString *tempDirectoryPath;
@property (strong, nonatomic, readonly) NSString *resultDirectoryPath;

@property (strong, nonatomic) NSString *tempPath;
@property (strong, nonatomic) NSString *resultPath;

@property (strong, nonatomic) NSFileHandle *handle;

@end

@implementation OCTFileDownloadOperation

#pragma mark -  Lifecycle

- (nullable instancetype)initWithTox:(nonnull OCTTox *)tox
                   tempDirectoryPath:(NSString *)tempDirectoryPath
                 resultDirectoryPath:(nonnull NSString *)resultDirectoryPath
                        friendNumber:(OCTToxFriendNumber)friendNumber
                          fileNumber:(OCTToxFileNumber)fileNumber
                            fileSize:(OCTToxFileSize)fileSize
                            userInfo:(id)userInfo
                       progressBlock:(nonnull OCTFileBaseOperationProgressBlock)progressBlock
                        successBlock:(nonnull OCTFileBaseOperationSuccessBlock)successBlock
                        failureBlock:(nonnull OCTFileBaseOperationFailureBlock)failureBlock
{
    NSParameterAssert(tempDirectoryPath);

    self = [super initWithTox:tox
                 friendNumber:friendNumber
                   fileNumber:fileNumber
                     fileSize:fileSize
                     userInfo:userInfo
                progressBlock:progressBlock
                 successBlock:successBlock
                 failureBlock:failureBlock];

    if (! self) {
        return nil;
    }

    _tempDirectoryPath = tempDirectoryPath;
    _resultDirectoryPath = resultDirectoryPath;

    return self;
}

#pragma mark -  Public

- (void)receiveChunk:(NSData *)chunk position:(OCTToxFileSize)position
{
    if (! chunk) {
        [self finishDownload];
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

    [self.handle writeData:chunk];
    [self updateBytesDone:self.bytesDone + chunk.length];
}

#pragma mark -  Override

- (void)operationStarted
{
    [super operationStarted];
    NSError *error;

    if (! [self generateTempAndResultPath:&error]) {
        [self finishWithError:error];
        return;
    }

    [[NSFileManager defaultManager] createFileAtPath:self.tempPath contents:nil attributes:nil];

    self.handle = [NSFileHandle fileHandleForWritingAtPath:self.tempPath];

    if (! self.handle) {
        OCTLogWarn(@"Cannot open file handle for path %@", self.tempPath);
        [self finishWithError:nil];
        return;
    }

    if (! [self.tox fileSendControlForFileNumber:self.fileNumber
                                    friendNumber:self.friendNumber
                                         control:OCTToxFileControlResume
                                           error:&error]) {
        [self finishWithError:error];
        return;
    }
}

#pragma mark -  Private

- (BOOL)generateTempAndResultPath:(NSError **)error
{
    if (! [self validateDirectory:self.tempDirectoryPath error:error]) {
        return NO;
    }

    if (! [self validateDirectory:self.resultDirectoryPath error:error]) {
        return NO;
    }

    NSString *fileName = [[NSUUID UUID] UUIDString];
    self.tempPath = [self.tempDirectoryPath stringByAppendingPathComponent:fileName];
    self.resultPath = [self.resultDirectoryPath stringByAppendingPathComponent:fileName];

    OCTLogInfo(@"temp path %@", self.tempPath);
    OCTLogInfo(@"result path %@", self.resultPath);

    return YES;
}

- (BOOL)validateDirectory:(NSString *)path error:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDirectory;
    BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];

    if (exists && ! isDirectory) {
        // TODO fill error
        return NO;
    }

    if (! exists) {
        if (! [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error]) {
            return NO;
        }
    }

    return YES;
}

- (void)finishDownload
{
    [self.handle synchronizeFile];
    self.handle = nil;

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSError *error;
    if (! [fileManager moveItemAtPath:self.tempPath toPath:self.resultPath error:&error]) {
        [self finishWithError:error];
        return;
    }

    [self finishWithSuccess:self.resultPath];
}

@end
