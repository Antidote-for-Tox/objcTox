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

    _output = fileOutput;

    return self;
}

#pragma mark -  Public

- (void)receiveChunk:(NSData *)chunk position:(OCTToxFileSize)position
{
    if (! chunk) {
        [self.output finishWriting];
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

    [self.output writeData:chunk];
    [self updateBytesDone:self.bytesDone + chunk.length];
}

#pragma mark -  Override

- (void)operationStarted
{
    [super operationStarted];
    NSError *error;

    [self.output prepareToWrite];

    if (! [self.tox fileSendControlForFileNumber:self.fileNumber
                                    friendNumber:self.friendNumber
                                         control:OCTToxFileControlResume
                                           error:&error]) {
        [self finishWithError:error];
        return;
    }
}

@end
