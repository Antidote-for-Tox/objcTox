//
//  OCTMessageText.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTMessageText.h"

@interface OCTMessageText ()

@end

@implementation OCTMessageText

- (NSString *)description
{
    NSString *description = [super description];

    const NSUInteger maxSymbols = 3;
    NSString *text = self.text.length > maxSymbols ? [self.text substringToIndex : maxSymbols] : @"";

    return [description stringByAppendingFormat:@"OCTMessageText %@..., length %lu", text, (unsigned long)self.text.length];
}

@end
