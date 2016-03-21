//
//  OCTFileBaseOperation.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileBaseOperation.h"
#import "OCTFileBaseOperation+Private.h"
#import "OCTLogging.h"

#import <QuartzCore/QuartzCore.h>

static const CFTimeInterval kMinUpdateProgressInterval = 1.0;

@interface OCTFileBaseOperation ()

@property (assign, atomic) BOOL privateExecuting;
@property (assign, atomic) BOOL privateFinished;

@property (weak, nonatomic, readonly, nullable) OCTTox *tox;

@property (assign, nonatomic, readonly) OCTToxFriendNumber friendNumber;
@property (assign, nonatomic, readonly) OCTToxFileNumber fileNumber;
@property (assign, nonatomic, readonly) OCTToxFileSize fileSize;

@property (assign, nonatomic, readwrite) OCTToxFileSize bytesDone;
@property (assign, nonatomic, readwrite) CGFloat progress;
@property (assign, nonatomic, readwrite) OCTToxFileSize bytesPerSecond;
@property (assign, nonatomic, readwrite) CFTimeInterval eta;

@property (copy, nonatomic) OCTFileBaseOperationProgressBlock progressBlock;
@property (copy, nonatomic) OCTFileBaseOperationSuccessBlock successBlock;
@property (copy, nonatomic) OCTFileBaseOperationFailureBlock failureBlock;

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
                        friendNumber:(OCTToxFriendNumber)friendNumber
                          fileNumber:(OCTToxFileNumber)fileNumber
                            fileSize:(OCTToxFileSize)fileSize
                            userInfo:(NSDictionary *)userInfo
                       progressBlock:(nullable OCTFileBaseOperationProgressBlock)progressBlock
                        successBlock:(nullable OCTFileBaseOperationSuccessBlock)successBlock
                        failureBlock:(nullable OCTFileBaseOperationFailureBlock)failureBlock
{
    NSParameterAssert(tox);
    NSParameterAssert(fileSize > 0);

    self = [super init];

    if (! self) {
        return nil;
    }

    _operationId = [[self class] operationIdFromFileNumber:fileNumber friendNumber:friendNumber];

    _tox = tox;

    _friendNumber = friendNumber;
    _fileNumber = fileNumber;
    _fileSize = fileSize;

    _progress = 0.0;
    _bytesPerSecond = 0;
    _eta = 0;

    _userInfo = userInfo;

    _progressBlock = [progressBlock copy];
    _successBlock = [successBlock copy];
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

#pragma mark -  Private category

- (void)updateBytesDone:(OCTToxFileSize)bytesDone
{
    self.bytesDone = bytesDone;

    CFTimeInterval time = CACurrentMediaTime();

    CFTimeInterval deltaTime = time - self.lastUpdateProgressTime;

    if (deltaTime > kMinUpdateProgressInterval) {
        OCTToxFileSize deltaBytes = bytesDone - self.lastUpdateBytesDone;
        OCTToxFileSize bytesLeft = self.fileSize - bytesDone;

        self.lastUpdateProgressTime = time;
        self.lastUpdateBytesDone = bytesDone;

        self.progress = (CGFloat)bytesDone / self.fileSize;
        self.bytesPerSecond = deltaBytes / deltaTime;

        if (bytesDone) {
            self.eta = deltaTime * bytesLeft / deltaBytes;
        }

        OCTLogInfo(@"progress %.2f, bytes per second %lld, eta %.0f seconds", self.progress, self.bytesPerSecond, self.eta);
        if (self.progressBlock) {
            self.progressBlock(self);
        }
    }
}

- (void)operationStarted
{
    OCTLogInfo(@"start downloading file with identifier %@", self.operationId);
}

- (void)finishWithSuccess
{
    OCTLogInfo(@"finished with success");

    self.executing = NO;
    self.finished = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.successBlock) {
            self.successBlock(self);
        }
    });
}

- (void)finishWithError:(nonnull NSError *)error
{
    NSParameterAssert(error);

    OCTLogInfo(@"finished with error %@", error);

    self.executing = NO;
    self.finished = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.failureBlock) {
            self.failureBlock(self, error);
        }
    });
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

@end
