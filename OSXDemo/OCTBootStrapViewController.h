// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
