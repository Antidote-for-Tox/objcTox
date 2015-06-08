//
//  OCTFriendsContainer.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTFriend.h"
#import "OCTManagerConstants.h"

@class OCTFriendsContainer;
@protocol OCTFriendsContainerDelegate <NSObject>

@optional

/**
 * Method called on any friend updates (friend added, removed, or some of friend properties updated).
 *
 * @param container Container that was updated.
 * @param inserted NSIndexSet with indexes of friends that were inserted;
 * @param removed NSIndexSet with indexes of friends that were removed;
 * @param updated NSIndexSet with indexes of friends that were updated.
 */
- (void)friendsContainerUpdate:(OCTFriendsContainer *)container
                   insertedSet:(NSIndexSet *)inserted
                    removedSet:(NSIndexSet *)removed
                    updatedSet:(NSIndexSet *)updated;

/**
 * Method call when friend gets updated.
 *
 * @param container Container that was updated.
 * @param friend Friend that was updated.
 */
- (void)friendsContainer:(OCTFriendsContainer *)container friendUpdated:(OCTFriend *)friend;

@end

@interface OCTFriendsContainer : NSObject

@property (weak, nonatomic) id<OCTFriendsContainerDelegate> delegate;

/**
 * The sort to be used for friends. Sort is saved in settings and remains same after relaunch.
 *
 * @warning After assigning this property all friends will be resorted, so you'll get different results from methods below.
 */
@property (assign, nonatomic) OCTFriendsSort friendsSort;

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
