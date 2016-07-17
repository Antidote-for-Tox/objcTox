//
//  OCTMessageAbstract.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 14.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTObject.h"

@class OCTFriend;
@class OCTChat;
@class OCTMessageText;
@class OCTMessageFile;
@class OCTMessageCall;

/**
 * An abstract message that represents one chunk of chat history.
 *
 * Please note that all properties of this object are readonly.
 * You can change some of them only with appropriate method in OCTSubmanagerObjects.
 */
@interface OCTMessageAbstract : OCTObject

/**
 * The date interval when message was send/received.
 */
@property NSTimeInterval dateInterval;

/**
 * Unique identifier of friend that have send message.
 * If the message if outgoing senderUniqueIdentifier is nil.
 */
@property (nullable) NSString *senderUniqueIdentifier;

/**
 * The chat message message belongs to.
 */
@property (nonnull) NSString *chatUniqueIdentifier;

/**
 * Message has one of the following properties.
 */
@property (nullable) OCTMessageText *messageText;
@property (nullable) OCTMessageFile *messageFile;
@property (nullable) OCTMessageCall *messageCall;

/**
 * The date when message was send/received.
 */
- (nonnull NSDate *)date;

/**
 * Indicates if message is outgoing or incoming.
 * In case if it is incoming you can check `sender` property for message sender.
 */
- (BOOL)isOutgoing;

@end

RLM_ARRAY_TYPE(OCTMessageAbstract)
