//
//  OCTFriendRequestContainer.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 17.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTFriendRequest.h"

/**
 * On adding/removing friend request post kOCTFriendRequestContainerUpdateNotification notification.
 */
@interface OCTFriendRequestContainer : NSObject

/**
 * @return Total number of friend requests.
 */
- (NSUInteger)requestsCount;

/**
 * Returns friend request at specified index.
 *
 * @param index Index to get friend request. May be out of bounds, in this case nil will be returned.
 *
 * @return Request at index. If index is out of bounds nil will be returned.
 */
- (OCTFriendRequest *)requestAtIndex:(NSUInteger)index;

@end
