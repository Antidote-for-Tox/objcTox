//
//  OCTArray+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTArray.h"
#import "RLMResults.h"
#import "OCTConvertorProtocol.h"

@interface OCTArray (Private)

- (instancetype)initWithRLMResults:(RLMResults *)results convertor:(id<OCTConvertorProtocol>)convertor;

@end
