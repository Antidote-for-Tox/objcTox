//
//  OCTFileDataOutput.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 21.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "OCTFileDataOutput.h"

@interface OCTFileDataOutput ()

@property (strong, nonatomic) NSMutableData *tempData;
@property (strong, nonatomic) NSData *resultData;

@end

@implementation OCTFileDataOutput

#pragma mark -  OCTFileOutputProtocol

- (void)prepareToWrite
{
    self.tempData = [NSMutableData new];
}

- (void)writeData:(nonnull NSData *)data
{
    [self.tempData appendData:data];
}

- (void)finishWriting
{
    self.resultData = [self.tempData copy];
    self.tempData = nil;
}

@end
