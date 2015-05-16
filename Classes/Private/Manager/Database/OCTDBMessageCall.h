//
//  OCTDBMessageCall.h
//  objcTox
//
//  Created by Chuong Vu on 5/14/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "RLMObject.h"
#import "OCTMessageCall.h"

@interface OCTDBMessageCall : RLMObject

@property NSTimeInterval callDuration;

-(instancetype)initWithMessageCall:(OCTMessageCall *)call;

@end
