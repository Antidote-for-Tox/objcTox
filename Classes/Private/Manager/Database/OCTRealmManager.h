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
@class OCTFriend;
@class OCTChat;
@class OCTCall;
@class OCTMessageAbstract;
@class OCTSettingsStorageObject;
@class RLMResults;

@interface OCTRealmManager : NSObject

/**
 * Storage with all objcTox settings.
 */
@property (strong, nonatomic, readonly) OCTSettingsStorageObject *settingsStorage;

- (instancetype)initWithDatabasePath:(NSString *)path;

- (NSString *)path;

#pragma mark -  Basic methods

- (id)objectWithUniqueIdentifier:(NSString *)uniqueIdentifier class:(Class)class;
- (RBQFetchRequest *)fetchRequestForClass:(Class)class withPredicate:(NSPredicate *)predicate;

- (void)addObject:(OCTObject *)object;
- (void)deleteObject:(OCTObject *)object;

- (RLMResults *)objectsWithClass:(Class)class predicate:(NSPredicate *)predicate;

/**
 * All realm objects should be updated ONLY with this method.
 *
 * Specified object will be passed in block.
 */
- (void)updateObject:(OCTObject *)object withBlock:(void (^)(id theObject))updateBlock;

/**
 * You should be careful updating objects without notification - data can in RBQFetchedResultsController may be
 * inconsistent after updating. This method is designed to be used on startup before any user interaction.
 */
- (void)updateObjectsWithClass:(Class)class
                     predicate:(NSPredicate *)predicate
              sendNotification:(BOOL)sendNotification
                   updateBlock:(void (^)(id theObject))updateBlock;

- (void)notifyAboutObjectUpdate:(OCTObject *)object;

#pragma mark -  Other methods

- (OCTFriend *)friendWithFriendNumber:(OCTToxFriendNumber)friendNumber;
- (OCTChat *)getOrCreateChatWithFriend:(OCTFriend *)friend;
- (OCTCall *)createCallWithChat:(OCTChat *)chat status:(OCTCallStatus)status;

/**
 * Gets the current call for the chat if and only if it exists.
 * This will not create a call object.
 * @param chat The chat that is related to the call.
 * @return A call object if it exists, nil if no call is session for this call.
 */
- (OCTCall *)getCurrentCallForChat:(OCTChat *)chat;
- (void)removeChatWithAllMessages:(OCTChat *)chat;

- (OCTMessageAbstract *)addMessageWithText:(NSString *)text
                                      type:(OCTToxMessageType)type
                                      chat:(OCTChat *)chat
                                    sender:(OCTFriend *)sender
                                 messageId:(OCTToxMessageId)messageId;

- (OCTMessageAbstract *)addMessageWithFileNumber:(OCTToxFileNumber)fileNumber
                                        fileType:(OCTMessageFileType)fileType
                                        fileSize:(OCTToxFileSize)fileSize
                                        fileName:(NSString *)fileName
                                        filePath:(NSString *)filePath
                                         fileUTI:(NSString *)fileUTI
                                            chat:(OCTChat *)chat
                                          sender:(OCTFriend *)sender;

- (OCTMessageAbstract *)addMessageCall:(OCTCall *)call;

@end
