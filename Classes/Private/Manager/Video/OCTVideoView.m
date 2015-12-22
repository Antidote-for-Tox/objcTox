//
//  OCTVideoView.m
//  objcTox
//
//  Created by Chuong Vu on 6/21/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTVideoView.h"
@import Foundation;
@import AVFoundation;

@interface OCTVideoView ()

@property (strong, nonatomic) CIContext *coreImageContext;

@end

@implementation OCTVideoView

+ (instancetype)view
{
#if TARGET_OS_IPHONE
    OCTVideoView *videoView = [[self alloc] initWithFrame:CGRectZero];
#else
    OCTVideoView *videoView = [[self alloc] initWithFrame:CGRectZero pixelFormat:[self defaultPixelFormat]];
#endif
    [videoView finishInitializing];
    return videoView;
}

- (void)finishInitializing
{
#if TARGET_OS_IPHONE
    __weak OCTVideoView *weakSelf = self;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        OCTVideoView *strongSelf = weakSelf;
        strongSelf.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        strongSelf.coreImageContext = [CIContext contextWithEAGLContext:strongSelf.context];
    });

    self.enableSetNeedsDisplay = NO;
    // #warning TODO audio OSX
#endif
}

- (void)setImage:(CIImage *)image
{
    _image = image;
#if TARGET_OS_IPHONE
    [self display];
#else
    [self setNeedsDisplay:YES];
#endif
}

#if ! TARGET_OS_IPHONE
// OS X: we need to correct the viewport when the view size changes
- (void)reshape
{
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
}
#endif

- (void)drawRect:(CGRect)rect
{
#if TARGET_OS_IPHONE
    if (self.image) {

        glClearColor(0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        CGRect destRect = AVMakeRectWithAspectRatioInsideRect(self.image.extent.size, rect);

        CGFloat screenscale = self.window.screen.scale;

        destRect = CGRectApplyAffineTransform(destRect, CGAffineTransformMakeScale(screenscale, screenscale));

        [self.coreImageContext drawImage:self.image inRect:destRect fromRect:self.image.extent];
    }
#else
    [self.openGLContext makeCurrentContext];

    if (self.image) {
        CIContext *ctx = [CIContext contextWithCGLContext:self.openGLContext.CGLContextObj pixelFormat:self.openGLContext.pixelFormat.CGLPixelFormatObj colorSpace:nil options:nil];
        // The GL coordinate system goes from -1 to 1 on all axes by default.
        // We didn't set a matrix so use that instead of bounds.
        [ctx drawImage:self.image inRect:(CGRect) {-1, -1, 2, 2} fromRect:self.image.extent];
    }
    else {
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    glFlush();
#endif
}
@end
