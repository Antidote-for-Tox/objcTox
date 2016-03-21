//
//  OCTFileUploadOperation.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 20.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileBaseOperation.h"

@protocol OCTFileInputProtocol;

@interface OCTFileUploadOperation : OCTFileBaseOperation

@property (strong, nonatomic, readonly, nonnull) id<OCTFileInputProtocol> input;

/**
 * Create operation.
 *
 * @param fileInput Input to use as a source for file transfer.
 *
 * For other parameters description see OCTFileBaseOperation.
 */
- (nullable instancetype)initWithTox:(nonnull OCTTox *)tox
                           fileInput:(nonnull id<OCTFileInputProtocol>)fileInput
                        friendNumber:(OCTToxFriendNumber)friendNumber
                          fileNumber:(OCTToxFileNumber)fileNumber
                            fileSize:(OCTToxFileSize)fileSize
                            userInfo:(nullable NSDictionary *)userInfo
                       progressBlock:(nullable OCTFileBaseOperationProgressBlock)progressBlock
                        successBlock:(nullable OCTFileBaseOperationSuccessBlock)successBlock
                        failureBlock:(nullable OCTFileBaseOperationFailureBlock)failureBlock;

/**
 * Call this method to request next chunk.
 *
 * @param position The file or stream position from which to continue reading.
 * @param length The number of bytes requested for the current chunk.
 */
- (void)chunkRequestWithPosition:(OCTToxFileSize)position length:(size_t)length;

@end
