//
//  OCTConverterMessage.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTConverterProtocol.h"
#import "OCTConverterFriend.h"

@class OCTConverterChat;

@interface OCTConverterMessage : NSObject <OCTConverterProtocol>

@property (strong, nonatomic) OCTConverterFriend *converterFriend;
// OCTConverterChat has strong property with OCTConverterMessage.
@property (weak, nonatomic) OCTConverterChat *converterChat;

- (id)objectFromRLMObjectWithoutChat:(id)db;

@end
