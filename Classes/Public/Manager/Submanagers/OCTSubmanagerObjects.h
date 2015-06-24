//
//  OCTSubmanagerObjects.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTManagerConstants.h"

@class OCTObject;
@class OCTFriend;
@class OCTChat;
@class RBQFetchRequest;

@interface OCTSubmanagerObjects : NSObject

/**
 * Returns fetch request for specified type.
 *
 * @param type Type of fetch request.
 * @param predicate Predicate that represents search query.
 *
 * @return RBQFetchRequest for specified type.
 */
- (RBQFetchRequest *)fetchRequestForType:(OCTFetchRequestType)type withPredicate:(NSPredicate *)predicate;

/**
 * Returns object for specified type with uniqueIdentifier.
 *
 * @param uniqueIdentifier Unique identifier of object.
 * @param type Type of object.
 *
 * @return Object of specified type or nil, if object does not exist.
 */
- (OCTObject *)objectWithUniqueIdentifier:(NSString *)uniqueIdentifier forType:(OCTFetchRequestType)type;

#pragma mark -  Friends

/**
 * Sets nickname property for friend.
 *
 * @param friend Friend to change.
 * @param nickname New nickname.
 */
- (void)changeFriend:(OCTFriend *)friend nickname:(NSString *)nickname;

#pragma mark -  Chats

/**
 * Sets enteredText property for chat.
 *
 * @param chat Chat to change.
 * @param enteredText New text.
 */
- (void)changeChat:(OCTChat *)chat enteredText:(NSString *)enteredText;

/**
 * Sets lastReadDateInterval property for chat.
 *
 * @param chat Chat to change.
 * @param lastReadDateInterval New interval.
 */
- (void)changeChat:(OCTChat *)chat lastReadDateInterval:(NSTimeInterval)lastReadDateInterval;

@end
