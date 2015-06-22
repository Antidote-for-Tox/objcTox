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

    return [description stringByAppendingFormat:@"OCTMessageText %@", self.text];
}

@end
