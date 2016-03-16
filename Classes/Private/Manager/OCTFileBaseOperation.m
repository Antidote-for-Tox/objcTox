//
//  OCTFileBaseOperation.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileBaseOperation.h"
#import "OCTLogging.h"

#import <QuartzCore/QuartzCore.h>

static const CFTimeInterval kMinUpdateProgressInterval = 1.0;

@interface OCTFileBaseOperation ()

@property (assign, atomic) BOOL privateExecuting;
@property (assign, atomic) BOOL privateFinished;

@property (copy, nonatomic) void (^failureBlock)(NSError *);

@property (assign, nonatomic) CFTimeInterval lastUpdateProgressTime;
@property (assign, nonatomic) OCTToxFileSize lastUpdateBytesDone;

@end

@implementation OCTFileBaseOperation

#pragma mark -  Class methods

+ (NSString *)operationIdFromFileNumber:(OCTToxFileNumber)fileNumber friendNumber:(OCTToxFriendNumber)friendNumber
{
    return [NSString stringWithFormat:@"%d-%d", fileNumber, friendNumber];
}

#pragma mark -  Lifecycle

- (nullable instancetype)initWithTox:(nonnull OCTTox *)tox
                         fileStorage:(nonnull id<OCTFileStorageProtocol>)fileStorage
                        friendNumber:(OCTToxFriendNumber)friendNumber
                          fileNumber:(OCTToxFileNumber)fileNumber
                            fileSize:(OCTToxFileSize)fileSize
                        failureBlock:(nonnull void (^)(NSError *__nonnull error))failureBlock
{
    NSParameterAssert(tox);
    NSParameterAssert(fileStorage);
    NSParameterAssert(failureBlock);
    NSParameterAssert(fileSize > 0);

    self = [super init];

    if (! self) {
        return nil;
    }

    _operationId = [[self class] operationIdFromFileNumber:fileNumber friendNumber:friendNumber];

    _tox = tox;
    _fileStorage = fileStorage;

    _friendNumber = friendNumber;
    _fileNumber = fileNumber;
    _fileSize = fileSize;

    _failureBlock = [failureBlock copy];

    _bytesDone = 0;
    _lastUpdateProgressTime = 0;

    return self;
}

#pragma mark -  Properties

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    self.privateExecuting = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isExecuting
{
    return self.privateExecuting;
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    self.privateFinished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isFinished
{
    return self.privateFinished;
}

- (void)setBytesDone:(OCTToxFileSize)bytesDone
{
    _bytesDone = bytesDone;

    CFTimeInterval time = CACurrentMediaTime();

    CFTimeInterval deltaTime = time - self.lastUpdateProgressTime;

    if (deltaTime > kMinUpdateProgressInterval) {
        OCTToxFileSize deltaBytes = bytesDone - self.lastUpdateBytesDone;
        OCTToxFileSize bytesLeft = self.fileSize - bytesDone;

        self.lastUpdateProgressTime = time;
        self.lastUpdateBytesDone = bytesDone;

        CGFloat progress = (CGFloat)bytesDone / self.fileSize;
        OCTToxFileSize bytesPerSecond = deltaBytes / deltaTime;
        CFTimeInterval eta = 0.0;

        if (bytesDone) {
            eta = deltaTime * bytesLeft / deltaBytes;
        }

        [self sendProgressUpdate:progress bytesPerSecond:bytesPerSecond eta:eta];
    }
}

#pragma mark -  Public

- (void)operationStarted
{
    OCTLogInfo(@"start downloading file with identifier %@", self.operationId);
}

- (void)finishWithSuccess
{
    OCTLogInfo(@"finished with success");

    self.executing = NO;
    self.finished = YES;
}

- (void)finishWithError:(nonnull NSError *)error
{
    NSParameterAssert(error);

    OCTLogInfo(@"finished with error %@", error);

    self.executing = NO;
    self.finished = YES;

    self.failureBlock(error);
}

#pragma mark -  Override

- (void)start
{
    if (self.cancelled) {
        self.finished = YES;
        return;
    }

    self.executing = YES;

    self.lastUpdateProgressTime = CACurrentMediaTime();
    self.lastUpdateBytesDone = 0;

    [self operationStarted];
}

- (void)cancel
{
    [super cancel];
    OCTLogInfo(@"was cancelled");
}

- (BOOL)asynchronous
{
    return YES;
}

#pragma mark -  Private

- (void)sendProgressUpdate:(CGFloat)progress bytesPerSecond:(OCTToxFileSize)bytesPerSecond eta:(CFTimeInterval)eta
{
    OCTLogInfo(@"progress %.2f, bytes per second %lld, eta %.0f seconds", progress, bytesPerSecond, eta);
}

@end
