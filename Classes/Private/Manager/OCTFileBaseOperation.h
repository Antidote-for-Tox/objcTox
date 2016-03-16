//
//  OCTFileBaseOperation.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTTox.h"
#import "OCTToxConstants.h"
#import "OCTFileStorageProtocol.h"

@interface OCTFileBaseOperation : NSOperation

/**
 * Identifier of operation, unique for all active file operations.
 */
@property (strong, nonatomic, readonly, nonnull) NSString *operationId;

@property (weak, nonatomic, readonly, nullable) OCTTox *tox;
@property (weak, nonatomic, readonly) id<OCTFileStorageProtocol> fileStorage;

@property (assign, nonatomic, readonly) OCTToxFriendNumber friendNumber;
@property (assign, nonatomic, readonly) OCTToxFileNumber fileNumber;
@property (assign, nonatomic, readonly) OCTToxFileSize fileSize;

/**
 * Update this property with downloaded/uploaded bytes.
 *
 * When updating property all progress listeners will be automatically updated
 */
@property (assign, nonatomic) OCTToxFileSize bytesDone;

/**
 * Creates operation id from file and friend number.
 */
+ (nonnull NSString *)operationIdFromFileNumber:(OCTToxFileNumber)fileNumber friendNumber:(OCTToxFriendNumber)friendNumber;

/**
 * Create operation.
 *
 * @param operationId Identifier of operation. Should be unique for all active file operations.
 * @param tox Tox object to download from.
 */
- (nullable instancetype)initWithTox:(nonnull OCTTox *)tox
                         fileStorage:(nonnull id<OCTFileStorageProtocol>)fileStorage
                        friendNumber:(OCTToxFriendNumber)friendNumber
                          fileNumber:(OCTToxFileNumber)fileNumber
                            fileSize:(OCTToxFileSize)fileSize
                        failureBlock:(nonnull void (^)(NSError *__nonnull error))failureBlock;

/**
 * Override this method to start custom actions. Call finish when operation is done.
 */
- (void)operationStarted NS_REQUIRES_SUPER;

/**
 * Call this method in case if operation was finished or cancelled.
 */
- (void)finishWithSuccess;

/**
 * Call this method in case if operation was finished or cancelled with error.
 *
 * @param error Pass error if occured, nil on success.
 */
- (void)finishWithError:(nonnull NSError *)error;

@end
