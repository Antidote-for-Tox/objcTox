//
//  OCTVideoView.m
//  objcTox
//
//  Created by Chuong Vu on 6/21/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTVideoView.h"
@import Foundation;

@interface OCTVideoView ()

@property (strong, nonatomic) CIContext *coreImageContext;

@end

@implementation OCTVideoView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (! self) {
        return nil;
    }

    __weak OCTVideoView *weakSelf = self;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
#if TARGET_OS_IPHONE
        OCTVideoView *strongSelf = weakSelf;
        strongSelf.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        strongSelf.coreImageContext = [CIContext contextWithEAGLContext:strongSelf.context];
#else
#warning TODO audio OSX
#endif
    });

#if TARGET_OS_IPHONE
    self.enableSetNeedsDisplay = NO;
#else
#warning TODO audio OSX
#endif

    return self;
}

- (void)setImage:(CIImage *)image
{
    _image = image;
    [self display];
}

- (void)drawRect:(CGRect)rect
{
#if TARGET_OS_IPHONE
    if (self.image) {
        CGFloat scale = self.window.screen.scale;
        CGRect destRect = CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeScale(scale, scale));
        [self.coreImageContext drawImage:self.image inRect:destRect fromRect:self.image.extent];
    }
#else
#warning TODO audio OSX
#endif
}
@end
