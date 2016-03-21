//
//  OCTPixelBufferPool.m
//  objcTox
//
//  Created by Chuong Vu on 8/5/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTPixelBufferPool.h"
#import "OCTLogging.h"

@interface OCTPixelBufferPool ()

@property (nonatomic, assign) CVPixelBufferPoolRef pool;
@property (nonatomic, assign) OSType formatType;
@property (nonatomic, assign) OCTToxAVVideoWidth width;
@property (nonatomic, assign) OCTToxAVVideoHeight height;

@end

@implementation OCTPixelBufferPool

#pragma mark - Lifecycle

- (instancetype)initWithFormat:(OSType)format;
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _formatType = format;

    return self;
}

- (void)dealloc
{
    if (self.pool) {
        CFRelease(self.pool);
    }
}

#pragma mark - Public

- (BOOL)createPixelBuffer:(CVPixelBufferRef *)bufferRef width:(OCTToxAVVideoWidth)width height:(OCTToxAVVideoHeight)height
{
    BOOL success = YES;
    if (! self.pool) {
        success = [self createPoolWithWidth:width height:height format:self.formatType];
    }

    if ((self.width != width) || (self.height != height)) {
        success = [self createPoolWithWidth:width height:height format:self.formatType];
    }

    if (! success) {
        return NO;
    }

    return [self createPixelBuffer:bufferRef];
}

#pragma mark - Private

- (BOOL)createPoolWithWidth:(OCTToxAVVideoWidth)width height:(OCTToxAVVideoHeight)height format:(OSType)format
{
    if (self.pool) {
        CFRelease(self.pool);
    }

    self.width = width;
    self.height = height;

    NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{},
                                            (id)kCVPixelBufferHeightKey : @(height),
                                            (id)kCVPixelBufferWidthKey : @(width),
                                            (id)kCVPixelBufferPixelFormatTypeKey : @(format)};

    CVReturn success = CVPixelBufferPoolCreate(kCFAllocatorDefault,
                                               NULL,
                                               (__bridge CFDictionaryRef)(pixelBufferAttributes),
                                               &_pool);

    if (success != kCVReturnSuccess) {
        OCTLogWarn(@"failed to create CVPixelBufferPool error:%d", success);

    }

    return (success == kCVReturnSuccess);
}

- (BOOL)createPixelBuffer:(CVPixelBufferRef *)bufferRef
{
    CVReturn success = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault,
                                                          self.pool,
                                                          bufferRef);

    if (success != kCVReturnSuccess) {
        OCTLogWarn(@"Failed to create pixelBuffer error:%d", success);
    }

    return (success == kCVReturnSuccess);
}

@end
