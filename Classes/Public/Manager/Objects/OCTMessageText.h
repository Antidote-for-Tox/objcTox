//
//  OCTMessageText.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTObject.h"
#import "OCTToxConstants.h"

@class OCTToxConstants;

/**
 * Simple text message.
 *
 * Please note that all properties of this object are readonly.
 * You can change some of them only with appropriate method in OCTSubmanagerObjects.
 */
@interface OCTMessageText : OCTObject

/**
 * The text of the message.
 */
@property NSString *text;

/**
 * Indicate if message is delivered. Actual only for outgoing messages.
 */
@property BOOL isDelivered;

/**
 * Type of the message.
 */
@property OCTToxMessageType type;

@property OCTToxMessageId messageId;

@end

RLM_ARRAY_TYPE(OCTMessageText)
