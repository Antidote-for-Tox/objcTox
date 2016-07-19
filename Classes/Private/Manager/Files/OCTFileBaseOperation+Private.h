//
//  OCTFileBaseOperation+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileBaseOperation.h"

@interface OCTFileBaseOperation (Private)

@property (weak, nonatomic, readonly, nullable) OCTTox *tox;

@property (assign, nonatomic, readonly) OCTToxFriendNumber friendNumber;
@property (assign, nonatomic, readonly) OCTToxFileNumber fileNumber;
@property (assign, nonatomic, readonly) OCTToxFileSize fileSize;

/**
 * Override this method to start custom actions. Call finish when operation is done.
 */
- (void)operationStarted NS_REQUIRES_SUPER;

/**
 * Override this method to do clean up on operation cancellation.
 */
- (void)operationWasCanceled NS_REQUIRES_SUPER;

/**
 * Call this method to change bytes done value.
 */
- (void)updateBytesDone:(OCTToxFileSize)bytesDone;

/**
 * Call this method in case if operation was finished.
 */
- (void)finishWithSuccess;

/**
 * Call this method in case if operation was finished or cancelled with error.
 *
 * @param error Pass error if occured, nil on success.
 */
- (void)finishWithError:(nonnull NSError *)error;

@end
