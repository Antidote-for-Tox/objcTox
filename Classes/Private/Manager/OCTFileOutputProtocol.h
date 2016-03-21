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
 */
- (void)prepareToWrite;

/**
 * Write data to output.
 *
 * @param data Data to write.
 */
- (void)writeData:(nonnull NSData *)data;

/**
 * This method is called after last writeData: method.
 */
- (void)finishWriting;

@end
