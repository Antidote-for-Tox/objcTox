//
//  OCTMessageFile.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTMessageFile.h"

@interface OCTMessageFile ()

@end

@implementation OCTMessageFile

#pragma mark -  Public

- (NSString *)description
{
    NSString *description = [super description];

    const NSUInteger maxSymbols = 3;
    NSString *fileName = self.fileName.length > maxSymbols ? [self.fileName substringToIndex : maxSymbols] : @"";

    return [description stringByAppendingFormat:@"OCTMessageFile with fileName = %@..., fileSize = %llu",
            fileName, self.fileSize];
}

@end
