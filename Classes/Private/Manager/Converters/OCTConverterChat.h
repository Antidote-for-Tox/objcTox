//
//  OCTConverterChat.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTConverterProtocol.h"
#import "OCTConverterMessage.h"
#import "OCTConverterFriend.h"

@interface OCTConverterChat : NSObject <OCTConverterProtocol>

@property (strong, nonatomic) OCTConverterMessage *converterMessage;
@property (strong, nonatomic) OCTConverterFriend *converterFriend;

@end
