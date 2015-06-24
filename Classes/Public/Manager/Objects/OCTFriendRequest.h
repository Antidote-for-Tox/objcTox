//
//  OCTFriendRequest.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTObject.h"

/**
 * Please note that all properties of this object are readonly.
 * You can change some of them only with appropriate method in OCTSubmanagerObjects.
 */
@interface OCTFriendRequest : OCTObject

/**
 * Public key of a friend.
 */
@property NSString *publicKey;

/**
 * Message that friend did send with friend request.
 */
@property NSString *message;

/**
 * Date interval when friend request was received (since 1970).
 */
@property NSTimeInterval dateInterval;

/**
 * Date when friend request was received.
 */
- (NSDate *)date;

@end

RLM_ARRAY_TYPE(OCTFriendRequest)
