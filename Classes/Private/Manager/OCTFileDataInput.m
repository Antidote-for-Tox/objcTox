//
//  OCTFileDataInput.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 21.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileDataInput.h"

@interface OCTFileDataInput ()

@property (strong, nonatomic, readonly) NSData *data;

@end

@implementation OCTFileDataInput

#pragma mark -  Lifecycle

- (nullable instancetype)initWithData:(nonnull NSData *)data
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _data = data;

    return self;
}

#pragma mark -  OCTFileInputProtocol

- (void)prepareToRead
{
    // nop
}

- (nonnull NSData *)bytesWithPosition:(OCTToxFileSize)position length:(size_t)length
{
    return [self.data subdataWithRange:NSMakeRange(position, length)];
}

@end
