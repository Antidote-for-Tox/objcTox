//
//  OCTConversationViewController.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 23.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCTManager.h"

@interface OCTConversationViewController : UIViewController

- (instancetype)initWithManager:(OCTManager *)manager chat:(OCTChat *)chat;

@end
