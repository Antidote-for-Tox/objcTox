//
//  OCTDBMessageText.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDBMessageAbstract.h"
#import "OCTMessageText.h"

@interface OCTDBMessageText : OCTDBMessageAbstract

@property NSString *text;
@property BOOL isDelivered;

- (instancetype)initWithMessageText:(OCTMessageText *)message;

/**
 * Please note that OCTFriend isn't stored in database.
 * OCTMessageAbstract object will have sender with filled friendNumber and empty other fields.
 */
- (OCTMessageText *)message;

@end
