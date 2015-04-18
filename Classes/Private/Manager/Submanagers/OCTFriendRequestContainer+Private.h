//
//  OCTFriendRequestContainer+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 17.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTFriendRequestContainer.h"

@interface OCTFriendRequestContainer (Private)

- (instancetype)initWithFriendRequestsArray:(NSArray *)array;

- (void)addRequest:(OCTFriendRequest *)request;
- (void)removeRequest:(OCTFriendRequest *)request;

@end
