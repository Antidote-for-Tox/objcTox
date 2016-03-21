//
//  OCTFileUploadOperation.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 20.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileUploadOperation.h"
#import "OCTFileBaseOperation+Private.h"
#import "OCTFileInputProtocol.h"
#import "OCTLogging.h"
#import "NSError+OCTFile.h"

@interface OCTFileUploadOperation ()

@end

@implementation OCTFileUploadOperation

#pragma mark -  Public

- (nullable instancetype)initWithTox:(nonnull OCTTox *)tox
                           fileInput:(nonnull id<OCTFileInputProtocol>)fileInput
                        friendNumber:(OCTToxFriendNumber)friendNumber
                          fileNumber:(OCTToxFileNumber)fileNumber
                            fileSize:(OCTToxFileSize)fileSize
                            userInfo:(nullable NSDictionary *)userInfo
                       progressBlock:(nullable OCTFileBaseOperationProgressBlock)progressBlock
                        successBlock:(nullable OCTFileBaseOperationSuccessBlock)successBlock
                        failureBlock:(nullable OCTFileBaseOperationFailureBlock)failureBlock
{
    NSParameterAssert(fileInput);

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

    _input = fileInput;

    return self;
}

#pragma mark -  Public

- (void)chunkRequestWithPosition:(OCTToxFileSize)position length:(size_t)length
{
    if (length == 0) {
        [self finishWithSuccess];
        return;
    }

    NSData *data = [self.input bytesWithPosition:position length:length];

    if (! data) {
        [self finishWithError:[NSError sendFileErrorCannotReadFile]];
        return;
    }

    NSError *error;

    BOOL result;
    do {
        result = [self.tox fileSendChunkForFileNumber:self.fileNumber
                                         friendNumber:self.friendNumber
                                             position:position
                                                 data:data
                                                error:&error];

        if (! result) {
            [NSThread sleepForTimeInterval:0.01];
        }
    }
    while (! result && error.code == OCTToxErrorFileSendChunkSendq);

    if (! result) {
        OCTLogWarn(@"upload error %@", error);

        [self.tox fileSendControlForFileNumber:self.fileNumber
                                  friendNumber:self.friendNumber
                                       control:OCTToxFileControlCancel
                                         error:nil];

        [self finishWithError:[NSError acceptFileErrorFromToxFileSendChunkError:error.code]];
        return;
    }

    [self updateBytesDone:position + length];
}

#pragma mark -  Override

- (void)operationStarted
{
    [super operationStarted];

    if (! [self.input prepareToRead]) {
        [self finishWithError:[NSError sendFileErrorCannotReadFile]];
    }
}

@end
