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

/**
 * An abstract message that represents one chunk of chat history.
 */
@interface OCTMessageAbstract : OCTObject

/**
 * The date interval when message was send/received.
 */
@property NSTimeInterval dateInterval;

/**
 * The sender of the message. If the message if outgoing sender is nil.
 */
@property OCTFriend *sender;

/**
 * The chat message message belongs to.
 */
@property OCTChat *chat;

/**
 * Message has one of the following properties.
 */
@property OCTMessageText *messageText;
@property OCTMessageFile *messageFile;

/**
 * The date when message was send/received.
 */
- (NSDate *)date;

/**
 * Indicates if message is outgoing or incoming.
 * In case if it is incoming you can check `sender` property for message sender.
 */
- (BOOL)isOutgoing;

@end

RLM_ARRAY_TYPE(OCTMessageAbstract)
