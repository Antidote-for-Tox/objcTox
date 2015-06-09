//
//  OCTCall+Private.h
//  objcTox
//
//  Created by Chuong Vu on 6/6/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCall.h"

@interface OCTCall (Private)

- (instancetype)initWithChat:(OCTChat *)chat friend:(OCTFriend *)friend;

@property (strong, nonatomic, readwrite) OCTChat *chatSession;
@property (strong, nonatomic, readwrite) NSArray *friends;
@property (nonatomic, assign, readwrite) OCTCallStatus status;

@end
