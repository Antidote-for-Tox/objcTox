//
//  OCTObject.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 22.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTObject.h"

@implementation OCTObject

#pragma mark -  Class methods

+ (NSString *)primaryKey
{
    return NSStringFromSelector(@selector(uniqueIdentifier));
}

+ (NSDictionary *)defaultPropertyValues
{
    return @{
               NSStringFromSelector(@selector(uniqueIdentifier)) : [[NSUUID UUID] UUIDString],
    };
}

+ (NSArray *)requiredProperties
{
    return @[NSStringFromSelector(@selector(uniqueIdentifier))];
}

#pragma mark -  Public

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ with uniqueIdentifier %@", [self class], self.uniqueIdentifier];
}

- (BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }

    if (! [object isKindOfClass:[self class]]) {
        return NO;
    }

    OCTObject *o = object;

    return [self.uniqueIdentifier isEqualToString:o.uniqueIdentifier];
}

- (NSUInteger)hash
{
    return [self.uniqueIdentifier hash];
}

@end
