//
//  OCTVideoViewController.h
//  objcTox
//
//  Created by Chuong Vu on 8/1/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OCTSubmanagerCalls;
@class OCTCall;

@interface OCTVideoViewController : UIViewController

- (instancetype)initWithCallManager:(OCTSubmanagerCalls *)manager call:(OCTCall *)call;

@end
