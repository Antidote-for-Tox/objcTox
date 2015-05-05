//
//  OCTConverterFriend.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 03.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTConverterFriend.h"
#import "OCTDBFriend.h"

@implementation OCTConverterFriend

#pragma mark -  OCTConverterProtocol

- (NSString *)objectClassName
{
    return NSStringFromClass([OCTFriend class]);
}

- (NSObject *)objectFromRLMObject:(OCTDBFriend *)dbFriend
{
    NSParameterAssert(dbFriend);

    return [self.dataSource friendWithFriendNumber:(OCTToxFriendNumber)dbFriend.friendNumber];
}

- (RLMSortDescriptor *)rlmSortDescriptorFromDescriptor:(OCTSortDescriptor *)descriptor
{
    NSParameterAssert(descriptor);

    NSDictionary *mapping = @{
        NSStringFromSelector(@selector(friendNumber)) : NSStringFromSelector(@selector(friendNumber)),
    };

    NSString *rlmProperty = mapping[descriptor.property];

    if (! rlmProperty) {
        return nil;
    }

    return [RLMSortDescriptor sortDescriptorWithProperty:rlmProperty ascending:descriptor.ascending];
}

@end
