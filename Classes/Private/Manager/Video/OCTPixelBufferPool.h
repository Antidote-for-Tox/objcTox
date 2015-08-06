//
//  OCTPixelBufferPool.h
//  objcTox
//
//  Created by Chuong Vu on 8/5/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTToxAVConstants.h"
@import CoreVideo;

/**
 * This class helps with allocating and keeping CVPixelBuffers.
 */
@interface OCTPixelBufferPool : NSObject

- (instancetype)initWithFormat:(OSType)format;

/**
 * Grab a pixel buffer from the pool.
 * @param bufferRef Reference to the buffer ref.
 * @return YES on success, NO otherwise.
 */
- (BOOL)createPixelBuffer:(CVPixelBufferRef *)bufferRef width:(OCTToxAVVideoWidth)width height:(OCTToxAVVideoHeight)height;

@end
