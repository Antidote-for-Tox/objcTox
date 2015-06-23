//
//  OCTDBMessageCall.h
//  objcTox
//
//  Created by Chuong Vu on 5/14/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Realm/Realm.h>
#import "OCTMessageCall.h"

@interface OCTDBMessageCall : RLMObject

@property NSTimeInterval callDuration;
@property NSInteger callEvent;

- (instancetype)initWithMessageCall:(OCTMessageCall *)call;

@end
