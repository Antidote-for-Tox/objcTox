//
//  OCTMessageFile.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTMessageFile.h"

@interface OCTMessageFile ()

@property (assign, nonatomic, readwrite) OCTMessageFileType fileType;
@property (assign, nonatomic, readwrite) OCTToxFileSize fileSize;
@property (strong, nonatomic, readwrite) NSString *fileName;
@property (strong, nonatomic, readwrite) NSString *filePath;
@property (strong, nonatomic, readwrite) NSString *fileUTI;

@end

@implementation OCTMessageFile

#pragma mark -  Public

- (NSString *)description
{
    NSString *description = [super description];

    return [description stringByAppendingFormat:@"\fileName = %@\nfileSize = %llu", self.fileName, self.fileSize];
}

@end
