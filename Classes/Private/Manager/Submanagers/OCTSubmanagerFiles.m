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
#import "OCTToxConstants.h"
#import "OCTFileDownloadOperation.h"
#import "OCTFileUploadOperation.h"
#import "OCTRealmManager.h"
#import "OCTLogging.h"
#import "OCTMessageAbstract.h"
#import "OCTMessageFile.h"
#import "OCTFriend.h"
#import "OCTChat.h"
#import "OCTFileStorageProtocol.h"
#import "OCTFilePathInput.h"
#import "OCTFilePathOutput.h"
#import "OCTFileDataInput.h"
#import "OCTSettingsStorageObject.h"

static NSString *const kDownloadsTempDirectory = @"me.objcTox.downloads";

static NSString *const kProgressSubscribersKey = @"kProgressSubscribersKey";

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

- (void)dealloc
{
    [self.dataSource.managerGetNotificationCenter removeObserver:self];
}

- (void)configure
{
    [self.dataSource.managerGetNotificationCenter addObserver:self
                                                     selector:@selector(friendConnectionStatusChangeNotification:)
                                                         name:kOCTFriendConnectionStatusChangeNotification
                                                       object:nil];
    [self.dataSource.managerGetNotificationCenter addObserver:self
                                                     selector:@selector(userAvatarWasUpdatedNotification)
                                                         name:kOCTUserAvatarWasUpdatedNotification
                                                       object:nil];

    OCTLogInfo(@"cancelling pending files...");
    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fileType == %d OR fileType == %d OR fileType == %d",
                              OCTMessageFileTypeWaitingConfirmation, OCTMessageFileTypeLoading, OCTMessageFileTypePaused];

    [realmManager updateObjectsWithClass:[OCTMessageFile class] predicate:predicate sendNotification:NO updateBlock:^(OCTMessageFile *file) {
        file.fileType = OCTMessageFileTypeCanceled;
        OCTLogInfo(@"cancelling file %@", file);
    }];

    OCTLogInfo(@"cancelling pending files... done");

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *downloads = [self downloadsTempDirectory];
    OCTLogInfo(@"clearing downloads temp directory %@\ncontents %@",
               downloads,
               [fileManager contentsOfDirectoryAtPath:downloads error:nil]);
    [fileManager removeItemAtPath:downloads error:nil];
}

#pragma mark -  Public

- (void)sendData:(nonnull NSData *)data withFileName:(nonnull NSString *)fileName toChat:(nonnull OCTChat *)chat
{
    NSParameterAssert(data);
    NSParameterAssert(fileName);
    NSParameterAssert(chat);

    NSString *filePath = [[self uploadsDirectory] stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];

    if (! [data writeToFile:filePath atomically:NO]) {
        OCTLogWarn(@"cannot save data to temp directory.");
        return;
    }

    [self sendFile:filePath overrideFileName:fileName toChat:chat];
}

- (void)    sendFile:(nonnull NSString *)filePath
    overrideFileName:(nullable NSString *)overrideFileName
              toChat:(nonnull OCTChat *)chat
{
    NSParameterAssert(filePath);
    NSParameterAssert(chat);

    NSString *fileName = overrideFileName ?: [filePath lastPathComponent];
    OCTFriend *friend = [chat.friends firstObject];

    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];

    if (! attributes) {
        OCTLogWarn(@"cannot read file %@", filePath);
        return;
    }

    OCTToxFileSize fileSize = [attributes[NSFileSize] longLongValue];

    NSError *error;
    OCTToxFileNumber fileNumber = [[self.dataSource managerGetTox] fileSendWithFriendNumber:friend.friendNumber
                                                                                       kind:OCTToxFileKindData
                                                                                   fileSize:fileSize
                                                                                     fileId:nil
                                                                                   fileName:fileName
                                                                                      error:&error];

    if (fileNumber == kOCTToxFileNumberFailure) {
        OCTLogWarn(@"cannot send file %@", error);
        return;
    }

    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];
    OCTMessageAbstract *message = [realmManager addMessageWithFileNumber:fileNumber
                                                                fileType:OCTMessageFileTypeWaitingConfirmation
                                                                fileSize:fileSize
                                                                fileName:fileName
                                                                filePath:filePath
                                                                 fileUTI:[self fileUTIFromFileName:fileName]
                                                                    chat:chat
                                                                  sender:nil];

    NSDictionary *userInfo = [self createOperationUserInfo];
    OCTFilePathInput *input = [[OCTFilePathInput alloc] initWithFilePath:filePath];

    OCTFileUploadOperation *operation = [[OCTFileUploadOperation alloc] initWithTox:[self.dataSource managerGetTox]
                                                                          fileInput:input
                                                                       friendNumber:friend.friendNumber
                                                                         fileNumber:fileNumber
                                                                           fileSize:fileSize
                                                                           userInfo:userInfo
                                                                      progressBlock:[self fileProgressBlockWithMessage:message]
                                                                       successBlock:[self fileSuccessBlockWithMessage:message]
                                                                       failureBlock:[self fileFailureBlockWithMessage:message]];

    [self.queue addOperation:operation];
}

- (void)acceptFileTransfer:(OCTMessageAbstract *)message
{
    if (! message.sender) {
        OCTLogWarn(@"specified wrong message: no sender. %@", message);
        return;
    }

    if (! message.messageFile) {
        OCTLogWarn(@"specified wrong message: no messageFile. %@", message);
        return;
    }

    if (message.messageFile.fileType != OCTMessageFileTypeWaitingConfirmation) {
        OCTLogWarn(@"specified wrong message: wrong file type, should be WaitingConfirmation. %@", message);
        return;
    }

    OCTFilePathOutput *output = [[OCTFilePathOutput alloc] initWithTempFolder:[self downloadsTempDirectory]
                                                                 resultFolder:[self downloadsDirectory]];

    [self updateMessageFile:message withBlock:^(OCTMessageFile *file) {
        file.fileType = OCTMessageFileTypeLoading;
        file.filePath = output.resultFilePath;
    }];

    NSDictionary *userInfo = [self createOperationUserInfo];

    OCTFileDownloadOperation *operation = [[OCTFileDownloadOperation alloc] initWithTox:self.dataSource.managerGetTox
                                                                             fileOutput:output
                                                                           friendNumber:message.sender.friendNumber
                                                                             fileNumber:message.messageFile.internalFileNumber
                                                                               fileSize:message.messageFile.fileSize
                                                                               userInfo:userInfo
                                                                          progressBlock:[self fileProgressBlockWithMessage:message]
                                                                           successBlock:[self fileSuccessBlockWithMessage:message]
                                                                           failureBlock:[self fileFailureBlockWithMessage:message]];

    [self.queue addOperation:operation];
}

- (void)cancelFileTransfer:(OCTMessageAbstract *)message
{
    if (! message.messageFile) {
        OCTLogWarn(@"specified wrong message: no messageFile. %@", message);
        return;
    }

    OCTFriend *friend = [message.chat.friends firstObject];

    [self.dataSource.managerGetTox fileSendControlForFileNumber:message.messageFile.internalFileNumber
                                                   friendNumber:friend.friendNumber
                                                        control:OCTToxFileControlCancel
                                                          error:nil];

    OCTFileBaseOperation *operation = [self operationWithFileNumber:message.messageFile.internalFileNumber
                                                       friendNumber:friend.friendNumber];

    if (operation) {
        [operation cancel];
    }

    [self updateMessageFile:message withBlock:^(OCTMessageFile *file) {
        file.fileType = OCTMessageFileTypeCanceled;
    }];
}

- (void)addProgressSubscriber:(nonnull id<OCTSubmanagerFilesProgressSubscriber>)subscriber
              forFileTransfer:(nonnull OCTMessageAbstract *)message
{
    if (! message.messageFile) {
        return;
    }

    OCTFriend *friend = [message.chat.friends firstObject];

    OCTFileBaseOperation *operation = [self operationWithFileNumber:message.messageFile.internalFileNumber
                                                       friendNumber:friend.friendNumber];

    if (! operation) {
        return;
    }

    [subscriber submanagerFilesOnProgressUpdate:operation.progress
                                        message:message
                                 bytesPerSecond:operation.bytesPerSecond
                                            eta:operation.eta];

    NSHashTable *progressSubscribers = operation.userInfo[kProgressSubscribersKey];
    [progressSubscribers addObject:subscriber];
}

- (void)removeProgressSubscriber:(nonnull id<OCTSubmanagerFilesProgressSubscriber>)subscriber
                 forFileTransfer:(nonnull OCTMessageAbstract *)message
{
    if (! message.messageFile) {
        return;
    }

    OCTFriend *friend = [message.chat.friends firstObject];

    OCTFileBaseOperation *operation = [self operationWithFileNumber:message.messageFile.internalFileNumber
                                                       friendNumber:friend.friendNumber];

    if (! operation) {
        return;
    }

    NSHashTable *progressSubscribers = operation.userInfo[kProgressSubscribersKey];
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
{
    OCTFileBaseOperation *operation = [self operationWithFileNumber:fileNumber friendNumber:friendNumber];

    if ([operation isKindOfClass:[OCTFileUploadOperation class]]) {
        [(OCTFileUploadOperation *)operation chunkRequestWithPosition:position length:length];
    }
    else {
        OCTLogWarn(@"operation not found with fileNumber %d friendNumber %d", fileNumber, friendNumber);
        [self.dataSource.managerGetTox fileSendControlForFileNumber:fileNumber friendNumber:friendNumber control:OCTToxFileControlCancel error:nil];
    }
}

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
    OCTFileBaseOperation *operation = [self operationWithFileNumber:fileNumber friendNumber:friendNumber];

    if ([operation isKindOfClass:[OCTFileDownloadOperation class]]) {
        [(OCTFileDownloadOperation *)operation receiveChunk:chunk position:position];
    }
    else {
        OCTLogWarn(@"operation not found with fileNumber %d friendNumber %d", fileNumber, friendNumber);
        [self.dataSource.managerGetTox fileSendControlForFileNumber:fileNumber friendNumber:friendNumber control:OCTToxFileControlCancel error:nil];
    }
}

#pragma mark -  NSNotification

- (void)friendConnectionStatusChangeNotification:(NSNotification *)notification
{
    OCTFriend *friend = notification.object;

    if (! friend) {
        OCTLogWarn(@"no friend received in notification %@, exiting", notification);
        return;
    }

    [self sendAvatarToFriend:friend];
}

- (void)userAvatarWasUpdatedNotification
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"connectionStatus != %d", OCTToxConnectionStatusNone];
    RLMResults *onlineFriends = [self.dataSource.managerGetRealmManager objectsWithClass:[OCTFriend class] predicate:predicate];

    for (OCTFriend *friend in onlineFriends) {
        [self sendAvatarToFriend:friend];
    }
}

#pragma mark -  Private

- (OCTFileBaseOperation *)operationWithFileNumber:(OCTToxFileNumber)fileNumber friendNumber:(OCTToxFriendNumber)friendNumber
{
    NSString *operationId = [OCTFileBaseOperation operationIdFromFileNumber:fileNumber friendNumber:friendNumber];

    for (OCTFileBaseOperation *operation in [self.queue operations]) {
        if ([operation.operationId isEqualToString:operationId]) {
            return operation;
        }
    }

    return nil;
}

- (void)createDirectoryIfNeeded:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL isDirectory;
    BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];

    if (exists && ! isDirectory) {
        [fileManager removeItemAtPath:path error:nil];
        exists = NO;
    }

    if (! exists) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (NSString *)downloadsDirectory
{
    id<OCTFileStorageProtocol> fileStorage = self.dataSource.managerGetFileStorage;

    NSString *path = fileStorage.pathForDownloadedFilesDirectory;
    [self createDirectoryIfNeeded:path];

    return path;
}

- (NSString *)uploadsDirectory
{
    id<OCTFileStorageProtocol> fileStorage = self.dataSource.managerGetFileStorage;

    NSString *path = fileStorage.pathForUploadedFilesDirectory;
    [self createDirectoryIfNeeded:path];

    return path;
}

- (NSString *)downloadsTempDirectory
{
    id<OCTFileStorageProtocol> fileStorage = self.dataSource.managerGetFileStorage;

    NSString *path = [fileStorage.pathForTemporaryFilesDirectory stringByAppendingPathComponent:kDownloadsTempDirectory];
    [self createDirectoryIfNeeded:path];

    return path;
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

- (OCTFileBaseOperationProgressBlock)fileProgressBlockWithMessage:(OCTMessageAbstract *)message
{
    return ^(OCTFileBaseOperation *__nonnull operation) {
               NSHashTable *progressSubscribers = operation.userInfo[kProgressSubscribersKey];

               for (id<OCTSubmanagerFilesProgressSubscriber> subscriber in progressSubscribers) {
                   [subscriber submanagerFilesOnProgressUpdate:operation.progress
                                                       message:message
                                                bytesPerSecond:operation.bytesPerSecond
                                                           eta:operation.eta];
               }
    };
}

- (OCTFileBaseOperationSuccessBlock)fileSuccessBlockWithMessage:(OCTMessageAbstract *)message
{
    __weak OCTSubmanagerFiles *weakSelf = self;

    return ^(OCTFileBaseOperation *__nonnull operation) {
               __strong OCTSubmanagerFiles *strongSelf = weakSelf;
               [strongSelf updateMessageFile:message withBlock:^(OCTMessageFile *file) {

            file.fileType = OCTMessageFileTypeReady;
        }];
    };
}

- (OCTFileBaseOperationFailureBlock)fileFailureBlockWithMessage:(OCTMessageAbstract *)message
{
    __weak OCTSubmanagerFiles *weakSelf = self;

    return ^(OCTFileBaseOperation *__nonnull operation, NSError *__nonnull error) {
               __strong OCTSubmanagerFiles *strongSelf = weakSelf;
               [strongSelf updateMessageFile:message withBlock:^(OCTMessageFile *file) {
            file.fileType = OCTMessageFileTypeCanceled;
        }];
    };
}

- (NSDictionary *)createOperationUserInfo
{
    return @{
               kProgressSubscribersKey : [NSHashTable weakObjectsHashTable],
    };
}

- (void)sendAvatarToFriend:(OCTFriend *)friend
{
    NSParameterAssert(friend);

    NSData *avatar = self.dataSource.managerGetRealmManager.settingsStorage.userAvatarData;

    if (! avatar) {
        [[self.dataSource managerGetTox] fileSendWithFriendNumber:friend.friendNumber
                                                             kind:OCTToxFileKindAvatar
                                                         fileSize:0
                                                           fileId:nil
                                                         fileName:nil
                                                            error:nil];
        return;
    }

    OCTToxFileSize fileSize = avatar.length;
    NSData *hash = [self.dataSource.managerGetTox hashData:avatar];

    NSError *error;
    OCTToxFileNumber fileNumber = [[self.dataSource managerGetTox] fileSendWithFriendNumber:friend.friendNumber
                                                                                       kind:OCTToxFileKindAvatar
                                                                                   fileSize:fileSize
                                                                                     fileId:hash
                                                                                   fileName:nil
                                                                                      error:&error];

    if (fileNumber == kOCTToxFileNumberFailure) {
        OCTLogWarn(@"cannot send file %@", error);
        return;
    }

    OCTFileDataInput *input = [[OCTFileDataInput alloc] initWithData:avatar];

    OCTFileUploadOperation *operation = [[OCTFileUploadOperation alloc] initWithTox:[self.dataSource managerGetTox]
                                                                          fileInput:input
                                                                       friendNumber:friend.friendNumber
                                                                         fileNumber:fileNumber
                                                                           fileSize:fileSize
                                                                           userInfo:nil
                                                                      progressBlock:nil
                                                                       successBlock:nil
                                                                       failureBlock:nil];

    [self.queue addOperation:operation];
}

@end
