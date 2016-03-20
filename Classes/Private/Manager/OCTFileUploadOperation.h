//
//  OCTFileUploadOperation.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 20.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileBaseOperation.h"

@interface OCTFileUploadOperation : OCTFileBaseOperation

/**
 * Create operation.
 *
 * @param filePath Path of file to upload.
 *
 * For other parameters description see OCTFileBaseOperation.
 */
- (nullable instancetype)initWithTox:(nonnull OCTTox *)tox
                            filePath:(nonnull NSString *)filePath
                        friendNumber:(OCTToxFriendNumber)friendNumber
                          fileNumber:(OCTToxFileNumber)fileNumber
                            fileSize:(OCTToxFileSize)fileSize
                            userInfo:(nullable id)userInfo
                       progressBlock:(nonnull OCTFileBaseOperationProgressBlock)progressBlock
                        successBlock:(nonnull OCTFileBaseOperationSuccessBlock)successBlock
                        failureBlock:(nonnull OCTFileBaseOperationFailureBlock)failureBlock;

/**
 * Call this method to request next chunk.
 *
 * @param position The file or stream position from which to continue reading.
 * @param length The number of bytes requested for the current chunk.
 */
- (void)chunkRequestWithPosition:(OCTToxFileSize)position length:(size_t)length;

@end
