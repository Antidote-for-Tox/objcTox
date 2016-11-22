// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>

#import "OCTToxConstants.h"
#import "OCTManagerConstants.h"

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

/**
 * Migrate unencrypted database to encrypted one.
 *
 * @param databasePath Path to unencrypted database.
 * @param encryptionKey Key used to encrypt database.
 * @param error Error parameter will be filled in case of failure. It will contain RLMRealm or NSFileManager error.
 *
 * @return YES on success, NO on failure.
 */
+ (BOOL)migrateToEncryptedDatabase:(NSString *)databasePath
                     encryptionKey:(NSData *)encryptionKey
                             error:(NSError **)error;

/**
 * Create RealmManager.
 *
 * @param fileURL path to Realm file. File will be created if it doesn't exist.
 * @param encryptionKey A 64-byte key to use to encrypt the data, or nil if encryption is not enabled.
 */
- (instancetype)initWithDatabaseFileURL:(NSURL *)fileURL encryptionKey:(NSData *)encryptionKey;

- (NSURL *)realmFileURL;

#pragma mark -  Basic methods

- (id)objectWithUniqueIdentifier:(NSString *)uniqueIdentifier class:(Class)class;

- (RLMResults *)objectsWithClass:(Class)class predicate:(NSPredicate *)predicate;

- (void)addObject:(OCTObject *)object;
- (void)deleteObject:(OCTObject *)object;

/*
 * All realm objects should be updated ONLY using following two methods.
 *
 * Specified object will be passed in block.
 */
- (void)updateObject:(OCTObject *)object withBlock:(void (^)(id theObject))updateBlock;

- (void)updateObjectsWithClass:(Class)class
                     predicate:(NSPredicate *)predicate
                   updateBlock:(void (^)(id theObject))updateBlock;

#pragma mark -  Other methods

- (OCTFriend *)friendWithPublicKey:(NSString *)publicKey;
- (OCTChat *)getOrCreateChatWithFriend:(OCTFriend *)friend;
- (OCTCall *)createCallWithChat:(OCTChat *)chat status:(OCTCallStatus)status;

/**
 * Gets the current call for the chat if and only if it exists.
 * This will not create a call object.
 * @param chat The chat that is related to the call.
 * @return A call object if it exists, nil if no call is session for this call.
 */
- (OCTCall *)getCurrentCallForChat:(OCTChat *)chat;

- (void)removeMessages:(NSArray<OCTMessageAbstract *> *)messages;
- (void)removeAllMessagesInChat:(OCTChat *)chat removeChat:(BOOL)removeChat;

/**
 * Converts all the OCTCalls to OCTMessageCalls.
 * Only use this when first starting the app or during termination.
 */
- (void)convertAllCallsToMessages;

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
