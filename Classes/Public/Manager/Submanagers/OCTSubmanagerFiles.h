//
//  OCTSubmanagerFiles.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCTMessageAbstract;
@protocol OCTSubmanagerFilesProgressSubscriber;

@interface OCTSubmanagerFiles : NSObject

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
