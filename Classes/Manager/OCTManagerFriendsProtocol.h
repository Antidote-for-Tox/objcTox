//
//  OCTManagerFriendsProtocol.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTFriendsContainerProtocol.h"

@protocol OCTManagerFriendsProtocol <NSObject>

/**
 * Container with all friends and friend requests.
 */
@property (strong, nonatomic, readonly) id<OCTFriendsContainerProtocol> container;

@end
