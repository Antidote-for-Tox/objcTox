//
//  OCTSubmanagerFiles.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCTMessageAbstract;
@class OCTChat;
@protocol OCTSubmanagerFilesProgressSubscriber;

@interface OCTSubmanagerFiles : NSObject

/**
 * Send given data to particular chat. After sending OCTMessageAbstract with messageFile will be added to this chat.
 * You can monitor progress using this message.
 *
 * File will be saved in uploaded files directory (see OCTFileStorageProtocol).
 *
 * @param data Data to send.
 * @param fileName Name of the file.
 * @param chat Chat to send data to.
 */
- (void)sendData:(nonnull NSData *)data withFileName:(nonnull NSString *)fileName toChat:(nonnull OCTChat *)chat;

/**
 * Send given file to particular chat. After sending OCTMessageAbstract with messageFile will be added to this chat.
 * You can monitor progress using this message.
 *
 * @param filePath Path of file to upload.
 * @param overrideFileName Optional parameter. By default file name from filePath will be used. You can override it
 * by passing this parameter.
 * @param chat Chat to send file to.
 */
- (void)    sendFile:(nonnull NSString *)filePath
    overrideFileName:(nullable NSString *)overrideFileName
              toChat:(nonnull OCTChat *)chat;

/**
 * Accept file transfer.
 *
 * @param message Message with file transfer. Message should be incoming and have OCTMessageFile with
 * fileType OCTMessageFileTypeWaitingConfirmation.
 * Otherwise nothing will happen.
 */
- (void)acceptFileTransfer:(nonnull OCTMessageAbstract *)message;

/**
 * Cancel file transfer. File transfer can be waiting confirmation or active.
 *
 * @param message Message with file transfer. Message should have OCTMessageFile. Otherwise nothing will happen.
 */
- (void)cancelFileTransfer:(nonnull OCTMessageAbstract *)message;

/**
 * Pause or resume file transfer.
 * - For pausing transfer should be in Loading state or paused by friend, otherwise nothing will happen.
 * - For resuming transfer should be in Paused state and paused by user, otherwise nothing will happen.
 *
 * @param pause Flag notifying of pausing/resuming file transfer.
 * @param message Message with file transfer. Message should have OCTMessageFile.
 */
- (void)pauseFileTransfer:(BOOL)pause message:(nonnull OCTMessageAbstract *)message;

/**
 * Add progress subscriber for given file transfer. Subscriber will receive progress immediately after subscribing.
 *
 * @param subscriber Object listening to progress protocol.
 * @param message Message with file transfer. Message should have OCTMessageFile. Otherwise nothing will happen.
 *
 * @warning Subscriber will be stored as weak reference, so it is safe to dealloc it without unsubscribing.
 */
- (void)addProgressSubscriber:(nonnull id<OCTSubmanagerFilesProgressSubscriber>)subscriber
              forFileTransfer:(nonnull OCTMessageAbstract *)message;

/**
 * Remove progress subscriber for given file transfer.
 *
 * @param subscriber Object listening to progress protocol.
 * @param message Message with file transfer. Message should have OCTMessageFile. Otherwise nothing will happen.
 */
- (void)removeProgressSubscriber:(nonnull id<OCTSubmanagerFilesProgressSubscriber>)subscriber
                 forFileTransfer:(nonnull OCTMessageAbstract *)message;

@end
