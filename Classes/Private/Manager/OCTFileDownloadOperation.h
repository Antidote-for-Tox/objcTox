//
//  OCTFileDownloadOperation.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileBaseOperation.h"

@class OCTTox;
@protocol OCTFileOutputProtocol;

/**
 * File operation for downloading file.
 *
 * When started will automatically send resume control to friend.
 */
@interface OCTFileDownloadOperation : OCTFileBaseOperation

@property (strong, nonatomic, readonly, nonnull) id<OCTFileOutputProtocol> output;

/**
 * Create operation.
 *
 * @param fileOutput Output to use as a destination for file transfer.
 *
 * For other parameters description see OCTFileBaseOperation.
 */
- (nullable instancetype)initWithTox:(nonnull OCTTox *)tox
                          fileOutput:(nonnull id<OCTFileOutputProtocol>)fileOutput
                        friendNumber:(OCTToxFriendNumber)friendNumber
                          fileNumber:(OCTToxFileNumber)fileNumber
                            fileSize:(OCTToxFileSize)fileSize
                            userInfo:(nullable NSDictionary *)userInfo
                       progressBlock:(nullable OCTFileBaseOperationProgressBlock)progressBlock
                        successBlock:(nullable OCTFileBaseOperationSuccessBlock)successBlock
                        failureBlock:(nullable OCTFileBaseOperationFailureBlock)failureBlock;

/**
 * Call this method to get next chunk to operation.
 *
 * @param chunk Next chunk of data to append to file.
 * @param position Position in file to append chunk.
 */
- (void)receiveChunk:(nullable NSData *)chunk position:(OCTToxFileSize)position;

@end
