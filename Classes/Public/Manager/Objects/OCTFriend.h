//
//  OCTFriend.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 10.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTObject.h"
#import "OCTToxConstants.h"

/**
 * Class that represents friend (or just simply contact).
 */
@interface OCTFriend : OCTObject

/**
 * Friend number that is unique for Tox.
 * In case if friend will be deleted, old id may be reused on new friend creation.
 */
@property OCTToxFriendNumber friendNumber;

/**
 * Nickname of friend.
 *
 * When friend is created it is set to the publicKey.
 * It is set to name when obtaining name for the first time.
 * After that name is unchanged (unless it is changed explicitly).
 */
@property NSString *nickname;

/**
 * Public key of a friend, is kOCTToxPublicKeyLength length.
 * Is constant, cannot be changed.
 */
@property NSString *publicKey;

/**
 * Name of a friend.
 *
 * May be empty.
 */
@property NSString *name;

/**
 * Status message of a friend.
 *
 * May be empty.
 */
@property NSString *statusMessage;

/**
 * Status message of a friend.
 */
@property OCTToxUserStatus status;

/**
 * Connection status message of a friend.
 */
@property OCTToxConnectionStatus connectionStatus;

/**
 * The date interval when friend was last seen online.
 * Contains actual information in case if friend has connectionStatus offline.
 */
@property NSTimeInterval lastSeenOnlineInterval;

/**
 * Whether friend is typing now in current chat.
 */
@property BOOL isTyping;

/**
 * The date when friend was last seen online.
 * Contains actual information in case if friend has connectionStatus offline.
 */
- (NSDate *)lastSeenOnline;

@end

RLM_ARRAY_TYPE(OCTFriend)
