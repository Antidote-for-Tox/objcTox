//
//  OCTRealmManager.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 22.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTToxConstants.h"
#import "OCTManagerConstants.h"

@class RBQFetchRequest;
@class OCTObject;
@class OCTFriendRequest;
@class OCTFriend;
@class OCTChat;
@class OCTCall;
@class OCTMessageAbstract;
@class OCTMessageText;
@class OCTMessageFile;

@interface OCTRealmManager : NSObject

- (instancetype)initWithDatabasePath:(NSString *)path;

- (NSString *)path;

#pragma mark -  Basic methods

- (OCTObject *)objectWithUniqueIdentifier:(NSString *)uniqueIdentifier class:(Class)class;
- (RBQFetchRequest *)fetchRequestForClass:(Class)class withPredicate:(NSPredicate *)predicate;

- (void)addObject:(OCTObject *)object;
- (void)deleteObject:(OCTObject *)object;

/**
 * All realm objects should be updated ONLY with this method.
 *
 * Specified object will be passed in block.
 */
- (void)updateObject:(OCTObject *)object withBlock:(void (^)(id theObject))updateBlock;

/**
 * Update objects without sending notification.
 * You should be careful with this method - data can in RBQFetchedResultsController may be
 * inconsistent after updating. This method is designed to be used on startup before any user interaction.
 */
- (void)updateObjectsWithoutNotification:(void (^)())updateBlock;

#pragma mark -  Other methods

- (OCTFriend *)friendWithFriendNumber:(OCTToxFriendNumber)friendNumber;
- (OCTChat *)getOrCreateChatWithFriend:(OCTFriend *)friend;
- (OCTCall *)getOrCreateCallWithChat:(OCTChat *)chat;
- (void)removeChatWithAllMessages:(OCTChat *)chat;

- (OCTMessageAbstract *)addMessageWithText:(NSString *)text
                                      type:(OCTToxMessageType)type
                                      chat:(OCTChat *)chat
                                    sender:(OCTFriend *)sender
                                 messageId:(OCTToxMessageId)messageId;

- (void)addMessageCall:(OCTCall *)call;

@end
