//
//  OCTDBCall.h
//  objcTox
//
//  Created by Chuong Vu on 6/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Realm/Realm.h>
#import "OCTDBFriend.h"
#import "OCTDBCall.h"
#import "OCTDBChat.h"

@interface OCTDBCall : RLMObject

/**
 * This unique identifier is tied to the same one as the OCTChat.
 * In an event an OCTChat is not found, a random one will be created.
 */
@property NSString *uniqueIdentifier;
@property OCTDBChat *chat;

@end
