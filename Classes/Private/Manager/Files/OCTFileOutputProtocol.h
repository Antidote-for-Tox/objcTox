//
//  OCTFileOutputProtocol.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 21.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OCTFileOutputProtocol <NSObject>

/**
 * Prepare input to write. This method will be called before first call to writeData:.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)prepareToWrite;

/**
 * Write data to output.
 *
 * @param data Data to write.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)writeData:(nonnull NSData *)data;

/**
 * This method is called after last writeData: method.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)finishWriting;

/**
 * This method is called if all progress was canceled. Do needed cleanup.
 */
- (void)cancel;

@end
