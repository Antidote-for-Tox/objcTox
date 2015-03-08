//
//  OCTDefaultFileStorage.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDefaultFileStorage.h"

@interface OCTDefaultFileStorage()

@property (copy, nonatomic) NSString *baseDirectory;
@property (copy, nonatomic) NSString *temporaryDirectory;

@end

@implementation OCTDefaultFileStorage

#pragma mark -  Lifecycle

- (instancetype)initWithBaseDirectory:(NSString *)baseDirectory temporaryDirectory:(NSString *)temporaryDirectory
{
    self = [super init];

    if (! self) {
        return nil;
    }

    self.baseDirectory = baseDirectory;
    self.temporaryDirectory = temporaryDirectory;

    return self;
}

#pragma mark -  OCTFileStorageProtocol

- (NSString *)pathForDownloadedFilesDirectory
{
    return [self.baseDirectory stringByAppendingPathComponent:@"downloads"];
}

- (NSString *)pathForUploadedFilesDirectory
{
    return [self.baseDirectory stringByAppendingPathComponent:@"uploads"];
}

- (NSString *)pathForTemporaryFilesDirectory
{
    return self.temporaryDirectory;
}

- (NSString *)pathForAvatarsDirectory
{
    return [self.baseDirectory stringByAppendingPathComponent:@"avatars"];
}

@end
