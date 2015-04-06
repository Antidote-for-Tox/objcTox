//
//  OCTManagerConstants.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

/**
 * Sort type for FriendsContainer.
 */
typedef NS_ENUM(NSUInteger, OCTManagerFriendsSort) {
    /**
     * Sort by friend name. In case if name will be nil, friends will be sorted by publicKey.
     */
    OCTManagerFriendsSortByName = 0,

    /**
     * Sort by status. Within groups friends will be sorted by name.
     * - online
     * - away
     * - busy
     * - offline
     */
    OCTManagerFriendsSortByStatus,
};
