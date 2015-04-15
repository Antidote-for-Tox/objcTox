//
//  OCTSubmanagerFriends.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTFriendsContainer.h"

@interface OCTSubmanagerFriends : NSObject

/**
 * Container with all friends and friend requests.
 */
@property (strong, nonatomic, readonly) OCTFriendsContainer *container;

@end
