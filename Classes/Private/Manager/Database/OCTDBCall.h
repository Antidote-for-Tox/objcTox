//
//  OCTDBCall.h
//  objcTox
//
//  Created by Chuong Vu on 6/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Realm/Realm.h>
#import "OCTDBChat.h"

@interface OCTDBCall : RLMObject

@property OCTDBChat *chat;

@end
