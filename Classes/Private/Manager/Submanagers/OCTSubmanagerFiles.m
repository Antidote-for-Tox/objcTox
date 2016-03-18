//
//  OCTSubmanagerFiles.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerFiles+Private.h"
#import "OCTSubmanagerFilesProgressSubscriber.h"
#import "OCTTox.h"
#import "OCTFileDownloadOperation.h"
#import "OCTRealmManager.h"
#import "OCTLogging.h"
#import "OCTMessageAbstract.h"
#import "OCTMessageFile.h"
#import "OCTFriend.h"

@interface OCTSubmanagerFiles ()

@property (strong, nonatomic, readonly) NSOperationQueue *queue;

@end

@implementation OCTSubmanagerFiles
@synthesize dataSource = _dataSource;

#pragma mark -  Lifecycle

- (instancetype)init
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _queue = [NSOperationQueue new];

    return self;
}

#pragma mark -  Public

- (void)acceptFileTransfer:(OCTMessageAbstract *)message
{
    if (! message.sender) {
        return;
    }

    if (! message.messageFile) {
        return;
    }

    if (message.messageFile.fileType != OCTMessageFileTypeWaitingConfirmation) {
        return;
    }

    [self updateMessageFile:message withBlock:^(OCTMessageFile *file) {
        file.fileType = OCTMessageFileTypeLoading;
    }];

    NSHashTable *progressSubscribers = [NSHashTable weakObjectsHashTable];

    OCTFileDownloadOperation *operation = [[OCTFileDownloadOperation alloc] initWithTox:self.dataSource.managerGetTox
                                                                            fileStorage:self.dataSource.managerGetFileStorage
                                                                           friendNumber:message.sender.friendNumber
                                                                             fileNumber:message.messageFile.internalFileNumber
                                                                               fileSize:message.messageFile.fileSize
                                                                               userInfo:progressSubscribers
                                                                          progressBlock:[self progressBlockWithMessage:message]
                                                                           successBlock:[self successBlockWithMessage:message]
                                                                            cancelBlock:[self cancelBlockWithMessage:message]
                                                                           failureBlock:[self failureBlockWithMessage:message]];

    [self.queue addOperation:operation];
}

- (void)cancelFileTransfer:(OCTMessageAbstract *)message
{}

- (void)addProgressSubscriber:(nonnull id<OCTSubmanagerFilesProgressSubscriber>)subscriber
              forFileTransfer:(nonnull OCTMessageAbstract *)message
{
    if (! message.messageFile) {
        return;
    }

    NSString *operationId;

    if (message.sender) {
        operationId = [OCTFileDownloadOperation operationIdFromFileNumber:message.messageFile.internalFileNumber
                                                             friendNumber:message.sender.friendNumber];
    }

    OCTFileBaseOperation *operation = [self operationWithId:operationId];

    if (! operation) {
        return;
    }

    [subscriber submanagerFilesOnProgressUpdate:operation.progress
                                        message:message
                                 bytesPerSecond:operation.bytesPerSecond
                                            eta:operation.eta];

    NSHashTable *progressSubscribers = operation.userInfo;
    [progressSubscribers addObject:subscriber];
}

- (void)removeProgressSubscriber:(nonnull id<OCTSubmanagerFilesProgressSubscriber>)subscriber
                 forFileTransfer:(nonnull OCTMessageAbstract *)message
{
    if (! message.messageFile) {
        return;
    }

    NSString *operationId;

    if (message.sender) {
        operationId = [OCTFileDownloadOperation operationIdFromFileNumber:message.messageFile.internalFileNumber
                                                             friendNumber:message.sender.friendNumber];
    }

    OCTFileBaseOperation *operation = [self operationWithId:operationId];

    if (! operation) {
        return;
    }

    NSHashTable *progressSubscribers = operation.userInfo;
    [progressSubscribers removeObject:subscriber];
}

#pragma mark -  OCTToxDelegate

- (void)     tox:(OCTTox *)tox fileReceiveControl:(OCTToxFileControl)control
    friendNumber:(OCTToxFriendNumber)friendNumber
      fileNumber:(OCTToxFileNumber)fileNumber
{}

- (void)     tox:(OCTTox *)tox fileChunkRequestForFileNumber:(OCTToxFileNumber)fileNumber
    friendNumber:(OCTToxFriendNumber)friendNumber
        position:(OCTToxFileSize)position
          length:(size_t)length
{}

- (void)     tox:(OCTTox *)tox fileReceiveForFileNumber:(OCTToxFileNumber)fileNumber
    friendNumber:(OCTToxFriendNumber)friendNumber
            kind:(OCTToxFileKind)kind
        fileSize:(OCTToxFileSize)fileSize
        fileName:(NSString *)fileName
{
    if (fileSize == 0) {
        OCTLogWarn(@"Received file with size 0, ignoring it.");
        [self.dataSource.managerGetTox fileSendControlForFileNumber:fileNumber friendNumber:friendNumber control:OCTToxFileControlCancel error:nil];
        return;
    }

    switch (kind) {
        case OCTToxFileKindData: {
            OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];
            OCTFriend *friend = [realmManager friendWithFriendNumber:friendNumber];
            OCTChat *chat = [realmManager getOrCreateChatWithFriend:friend];

            [realmManager addMessageWithFileNumber:fileNumber
                                          fileType:OCTMessageFileTypeWaitingConfirmation
                                          fileSize:fileSize
                                          fileName:fileName
                                          filePath:nil
                                           fileUTI:[self fileUTIFromFileName:fileName]
                                              chat:chat
                                            sender:friend];
            break;

        }
        case OCTToxFileKindAvatar:
            // none for now
            [self.dataSource.managerGetTox fileSendControlForFileNumber:fileNumber friendNumber:friendNumber control:OCTToxFileControlCancel error:nil];
            break;
    }
}

- (void)     tox:(OCTTox *)tox fileReceiveChunk:(NSData *)chunk
      fileNumber:(OCTToxFileNumber)fileNumber
    friendNumber:(OCTToxFriendNumber)friendNumber
        position:(OCTToxFileSize)position
{
    NSString *operationId = [OCTFileDownloadOperation operationIdFromFileNumber:fileNumber friendNumber:friendNumber];
    OCTFileDownloadOperation *operation = [self operationWithId:operationId];

    if (operation) {
        [operation receiveChunk:chunk position:position];
    }
    else {
        OCTLogWarn(@"operation not found with fileNumber %d friendNumber %d", fileNumber, friendNumber);
        [self.dataSource.managerGetTox fileSendControlForFileNumber:fileNumber friendNumber:friendNumber control:OCTToxFileControlCancel error:nil];
    }
}

#pragma mark -  Private

- (OCTFileBaseOperation *)operationWithId:(NSString *)operationId
{

    for (OCTFileDownloadOperation *operation in [self.queue operations]) {
        if ([operation.operationId isEqualToString:operationId]) {
            return operation;
        }
    }

    return nil;
}

- (NSString *)fileUTIFromFileName:(NSString *)fileName
{
    NSString *extension = [fileName pathExtension];

    if (! extension) {
        return nil;
    }

    return (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension,
        (__bridge CFStringRef)extension,
        NULL);
}

- (void)updateMessageFile:(OCTMessageAbstract *)message withBlock:(void (^)(OCTMessageFile *))block
{
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    [realmManager updateObject:message.messageFile withBlock:block];
    [realmManager notifyAboutObjectUpdate:message];
}

- (OCTFileBaseOperationProgressBlock)progressBlockWithMessage:(OCTMessageAbstract *)message
{
    return ^(OCTFileBaseOperation *__nonnull operation) {
               NSHashTable *progressSubscribers = operation.userInfo;

               for (id<OCTSubmanagerFilesProgressSubscriber> subscriber in progressSubscribers) {
                   [subscriber submanagerFilesOnProgressUpdate:operation.progress
                                                       message:message
                                                bytesPerSecond:operation.bytesPerSecond
                                                           eta:operation.eta];
               }
    };
}

- (OCTFileBaseOperationSuccessBlock)successBlockWithMessage:(OCTMessageAbstract *)message
{
    __weak OCTSubmanagerFiles *weakSelf = self;

    return ^(OCTFileBaseOperation *__nonnull operation) {
               __strong OCTSubmanagerFiles *strongSelf = weakSelf;
               [strongSelf updateMessageFile:message withBlock:^(OCTMessageFile *file) {
            file.fileType = OCTMessageFileTypeReady;
        }];
    };
}

- (OCTFileBaseOperationCancelBlock)cancelBlockWithMessage:(OCTMessageAbstract *)message
{
    __weak OCTSubmanagerFiles *weakSelf = self;

    return ^(OCTFileBaseOperation *__nonnull operation) {
               __strong OCTSubmanagerFiles *strongSelf = weakSelf;
               [strongSelf updateMessageFile:message withBlock:^(OCTMessageFile *file) {
            file.fileType = OCTMessageFileTypeCanceled;
        }];
    };
}

- (OCTFileBaseOperationFailureBlock)failureBlockWithMessage:(OCTMessageAbstract *)message
{
    __weak OCTSubmanagerFiles *weakSelf = self;

    return ^(OCTFileBaseOperation *__nonnull operation, NSError *__nonnull error) {
               __strong OCTSubmanagerFiles *strongSelf = weakSelf;
               [strongSelf updateMessageFile:message withBlock:^(OCTMessageFile *file) {
            file.fileType = OCTMessageFileTypeCanceled;
        }];
    };
}

@end
