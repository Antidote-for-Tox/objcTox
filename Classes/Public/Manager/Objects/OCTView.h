//
//  OCTView.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 21/08/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "TargetConditionals.h"

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>
typedef UIView OCTView;

#else

#import <AppKit/AppKit.h>
typedef NSView OCTView;

#endif
