//
//  OCTSortDescriptor.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSortDescriptor.h"

@interface OCTSortDescriptor()

@property (strong, nonatomic, readwrite) NSString *property;
@property (assign, nonatomic, readwrite) BOOL ascending;

@end

@implementation OCTSortDescriptor

#pragma mark -  Class methods

+ (instancetype)sortDescriptorWithProperty:(NSString *)property ascending:(BOOL)ascending
{
    NSParameterAssert(property);

    OCTSortDescriptor *descriptor = [OCTSortDescriptor new];
    descriptor.property = property;
    descriptor.ascending = ascending;

    return descriptor;
}

#pragma mark -  Public

- (NSString *)description
{
    return [NSString stringWithFormat:@"OCTSortDescriptor with property %@, ascending %@",
        self.property, (self.ascending ? @"YES" : @"NO")];
}

@end
