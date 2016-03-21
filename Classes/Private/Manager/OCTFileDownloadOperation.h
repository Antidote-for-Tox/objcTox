//
//  OCTFileDownloadOperation.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileBaseOperation.h"

@class OCTTox;

/**
 * File operation for downloading file.
 *
 * When started will automatically send resume control to friend.
 */
@interface OCTFileDownloadOperation : OCTFileBaseOperation

/**
 * Create operation.
 *
 * @param tempDirectoryPath Path to directory to store temporary files.
 * @param resultDirectoryPath Path to which file would be copied on success.
 *
 * For other parameters description see OCTFileBaseOperation.
 */
- (nullable instancetype)initWithTox:(nonnull OCTTox *)tox
                   tempDirectoryPath:(nonnull NSString *)tempDirectoryPath
                 resultDirectoryPath:(nonnull NSString *)resultDirectoryPath
                        friendNumber:(OCTToxFriendNumber)friendNumber
                          fileNumber:(OCTToxFileNumber)fileNumber
                            fileSize:(OCTToxFileSize)fileSize
                            userInfo:(nullable id)userInfo
                       progressBlock:(nonnull OCTFileBaseOperationProgressBlock)progressBlock
                        successBlock:(nonnull OCTFileBaseOperationSuccessBlock)successBlock
                        failureBlock:(nonnull OCTFileBaseOperationFailureBlock)failureBlock;

/**
 * Call this method to get next chunk to operation.
 *
 * @param chunk Next chunk of data to append to file.
 * @param position Position in file to append chunk.
 */
- (void)receiveChunk:(nullable NSData *)chunk position:(OCTToxFileSize)position;

@end
