//
//  OCTBootStrapViewController.h
//  objcTox
//
//  Created by Chuong Vu on 12/9/15.
//  Copyright © 2015 dvor. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OCTManagerConfiguration.h"

@class OCTBootStrapViewController;
@protocol OCTBootStrapViewDelegate <NSObject>

- (void)didBootStrap:(OCTBootStrapViewController *)controller;

@end

@interface OCTBootStrapViewController : NSViewController

@property (weak, nonatomic) id<OCTBootStrapViewDelegate> delegate;

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration;

@end
