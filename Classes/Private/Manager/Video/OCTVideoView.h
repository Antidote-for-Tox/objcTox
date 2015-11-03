//
//  OCTVideoView.h
//  objcTox
//
//  Created by Chuong Vu on 6/21/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTView.h"

@import GLKit;

#if TARGET_OS_IPHONE
@interface OCTVideoView : GLKView
#else
@interface OCTVideoView : NSOpenGLView
#endif

@property (strong, nonatomic) CIImage *image;

@end
