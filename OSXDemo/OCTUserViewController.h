//
//  OCTUserViewController.h
//  objcTox
//
//  Created by Chuong Vu on 12/11/15.
//  Copyright © 2015 dvor. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OCTSubmanagerUser.h"

@interface OCTUserViewController : NSViewController

- (instancetype)initWithManager:(OCTSubmanagerUser *)userManager;

@end
