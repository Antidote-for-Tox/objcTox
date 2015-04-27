//
//  OCTDBChat.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 27.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "RLMObject.h"
#import "RLMArray.h"
#import "OCTDBFriend.h"
#import "OCTDBMessageAbstract.h"

@interface OCTDBChat : RLMObject

@property RLMArray<OCTDBFriend> *friends;
@property OCTDBMessageAbstract *lastMessage;
@property NSString *enteredText;

// Realm truncates an NSDate to the second. A fix for this is in progress.
// See https://github.com/realm/realm-cocoa/issues/875
@property NSTimeInterval lastReadDateInterval;

@end
