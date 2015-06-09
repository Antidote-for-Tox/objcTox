//
//  OCTConverterCall.h
//  objcTox
//
//  Created by Chuong Vu on 6/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTConverterProtocol.h"
#import "OCTConverterChat.h"
@interface OCTConverterCall : NSObject <OCTConverterProtocol>

@property (strong, nonatomic) OCTConverterChat *converterChat;


@end
