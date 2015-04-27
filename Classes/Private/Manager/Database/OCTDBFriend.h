//
//  OCTDBFriend.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 27.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "RLMObject.h"

/**
 * OCTDBFriend stores only friendNumber. All other friend properties are dynamic and can be obtained from Tox.
 */
@interface OCTDBFriend : RLMObject

@property NSInteger friendNumber;

/**
 * Searches in realm for a friend with friendNumber. If friend is found returns it.
 * Creates new friend with friendNumber otherwise.
 */
+ (instancetype)findOrCreateFriendInRealm:(RLMRealm *)realm withFriendNumber:(NSInteger)friendNumber;

@end

RLM_ARRAY_TYPE(OCTDBFriend)

