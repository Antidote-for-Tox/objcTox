//
//  OCTFileDownloadOperation.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileDownloadOperation.h"
#import "OCTFileBaseOperation+Private.h"
#import "OCTFileOutputProtocol.h"
#import "OCTLogging.h"
#import "NSError+OCTFile.h"

@interface OCTFileDownloadOperation ()

@end

@implementation OCTFileDownloadOperation

#pragma mark -  Lifecycle

- (nullable instancetype)initWithTox:(nonnull OCTTox *)tox
                          fileOutput:(nonnull id<OCTFileOutputProtocol>)fileOutput
                        friendNumber:(OCTToxFriendNumber)friendNumber
                          fileNumber:(OCTToxFileNumber)fileNumber
                            fileSize:(OCTToxFileSize)fileSize
                            userInfo:(NSDictionary *)userInfo
                       progressBlock:(nullable OCTFileBaseOperationProgressBlock)progressBlock
                        successBlock:(nullable OCTFileBaseOperationSuccessBlock)successBlock
                        failureBlock:(nullable OCTFileBaseOperationFailureBlock)failureBlock
{
    NSParameterAssert(fileOutput);

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

    _output = fileOutput;

    return self;
}

#pragma mark -  Public

- (void)receiveChunk:(NSData *)chunk position:(OCTToxFileSize)position
{
    if (! chunk) {
        if ([self.output finishWriting]) {
            [self finishWithSuccess];
        }
        else {
            [self finishWithError:[NSError acceptFileErrorCannotWriteToFile]];
        }
        return;
    }

    if (self.bytesDone != position) {
        OCTLogWarn(@"bytesDone doesn't match position");
        [self.tox fileSendControlForFileNumber:self.fileNumber
                                  friendNumber:self.friendNumber
                                       control:OCTToxFileControlCancel
                                         error:nil];
        [self finishWithError:[NSError acceptFileErrorInternalError]];
        return;
    }

    if (! [self.output writeData:chunk]) {
        [self finishWithError:[NSError acceptFileErrorCannotWriteToFile]];
        return;
    }

    [self updateBytesDone:self.bytesDone + chunk.length];
}

#pragma mark -  Override

- (void)operationStarted
{
    [super operationStarted];

    if (! [self.output prepareToWrite]) {
        [self finishWithError:[NSError acceptFileErrorCannotWriteToFile]];
    }

    NSError *error;
    if (! [self.tox fileSendControlForFileNumber:self.fileNumber
                                    friendNumber:self.friendNumber
                                         control:OCTToxFileControlResume
                                           error:&error]) {
        OCTLogWarn(@"cannot send control %@", error);
        [self finishWithError:[NSError acceptFileErrorFromToxFileControl:error.code]];
        return;
    }
}

- (void)operationWasCanceled
{
    [super operationWasCanceled];

    [self.output cancel];
}

@end
