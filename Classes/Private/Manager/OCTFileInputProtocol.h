//
//  OCTFileInputProtocol.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 21.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTToxConstants.h"

@protocol OCTFileInputProtocol <NSObject>

/**
 * Prepare input to read. This method will be called before first call to bytesWithPosition:length:.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)prepareToRead;

/**
 * Provide bytes.
 *
 * @param position Start position to start reading from.
 * @param length Length of bytes to read.
 *
 * @return NSData on success, nil on failure
 */
- (nonnull NSData *)bytesWithPosition:(OCTToxFileSize)position length:(size_t)length;

@end
