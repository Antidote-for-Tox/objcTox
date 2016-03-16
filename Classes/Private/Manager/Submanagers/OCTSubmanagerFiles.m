//
//  OCTSubmanagerFiles.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerFiles+Private.h"
#import "OCTTox.h"
#import "OCTFileDownloadOperation.h"

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
        NSLog(@"Received with with size 0, ignoring it.");
        return;
    }

    OCTFileDownloadOperation *operation = [[OCTFileDownloadOperation alloc] initWithTox:self.dataSource.managerGetTox
                                                                            fileStorage:self.dataSource.managerGetFileStorage
                                                                           friendNumber:friendNumber
                                                                             fileNumber:fileNumber
                                                                               fileSize:fileSize
                                                                           failureBlock:^(NSError *error) { /* TODO */ }];

    [self.queue addOperation:operation];
}

- (void)     tox:(OCTTox *)tox fileReceiveChunk:(NSData *)chunk
      fileNumber:(OCTToxFileNumber)fileNumber
    friendNumber:(OCTToxFriendNumber)friendNumber
        position:(OCTToxFileSize)position
{
    OCTFileDownloadOperation *operation = [self operationWithFileNumber:fileNumber friendNumber:friendNumber];

    if (operation) {
        [operation receiveChunk:chunk position:position];
    }
    else {
        NSLog(@"---- operation not found");
        [self.dataSource.managerGetTox fileSendControlForFileNumber:fileNumber friendNumber:friendNumber control:OCTToxFileControlCancel error:nil];
    }
}

#pragma mark -  Private

- (NSOperation *)operationWithFileNumber:(OCTToxFileNumber)fileNumber friendNumber:(OCTToxFriendNumber)friendNumber
{
    NSString *operationId = [OCTFileDownloadOperation operationIdFromFileNumber:fileNumber friendNumber:friendNumber];

    for (OCTFileDownloadOperation *operation in [self.queue operations]) {
        if ([operation.operationId isEqualToString:operationId]) {
            return operation;
        }
    }

    return nil;
}

@end
