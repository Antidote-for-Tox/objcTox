//
//  OCTFriendsContainerProtocol.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTFriend.h"
#import "OCTManagerConstants.h"

/**
 * NSNotification posted on any friend updates (friend added, removed, or some of friend properties updated).
 * Always is posted on main thread.
 *
 * The notification object is nil. The userInfo dictionary contains dictionary with following keys:
 * kOCTFriendsContainerUpdateKeyInsertedSet - NSIndexSet with indexes of friends that were inserted;
 * kOCTFriendsContainerUpdateKeyRemovedSet  - NSIndexSet with indexes of friends that were removed;
 * kOCTFriendsContainerUpdateKeyUpdatedSet  - NSIndexSet with indexes of friends that were updated.
 * Note that on update there may be another friend than before.
 *
 * The order of friends may change (in case if friendSort changes or sort-dependant property changes).
 * In that case some of friends will be removed (see RemovedSet) and then added again (see InsertedSet).
 */
extern NSString *const kOCTFriendsContainerUpdateFriendsNotification;

extern NSString *const kOCTFriendsContainerUpdateKeyInsertedSet;
extern NSString *const kOCTFriendsContainerUpdateKeyRemovedSet;
extern NSString *const kOCTFriendsContainerUpdateKeyUpdatedSet;

@protocol OCTFriendsContainerProtocol <NSObject>

/**
 * The sort to be used for friends. Sort is saved in settings and remains same after relaunch.
 *
 * @warning After assigning this property all friends will be resorted, so you'll get different results from methods below.
 */
@property (assign, nonatomic) OCTManagerFriendsSort friendsSort;

/**
 * @return Total number of friends.
 */
- (NSUInteger)friendsCount;

/**
 * Returns friend at specified index.
 *
 * @param index Index to get friend. May be out of bounds, in this case nil will be returned.
 *
 * @return Friend at index. If index is out of bounds nil will be returned.
 */
- (OCTFriend *)friendAtIndex:(NSUInteger)index;

@end
