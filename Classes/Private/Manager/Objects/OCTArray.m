//
//  OCTArray.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTArray.h"
#import "OCTArray+Private.h"

@interface OCTArray()

@property (strong, nonatomic) RLMResults *results;
@property (strong, nonatomic) id<OCTConvertorProtocol> convertor;

@end

@implementation OCTArray

#pragma mark -  Lifecycle

- (instancetype)initWithRLMResults:(RLMResults *)results convertor:(id<OCTConvertorProtocol>)convertor
{
    NSParameterAssert(results);
    NSParameterAssert(convertor);

    self = [super init];

    if (! self) {
        return nil;
    }

    self.results = results;
    self.convertor = convertor;

    return self;
}

#pragma mark -  Properties

- (NSUInteger)count
{
    return self.results.count;
}

- (NSString *)objectClassName
{
    return self.convertor.objectClassName;
}

#pragma mark -  Public

- (NSObject *)firstObject
{
    RLMObject *object = [self.results firstObject];

    return object ? [self.convertor objectFromRLMObject:object] : nil;
}

- (NSObject *)lastObject
{
    RLMObject *object = [self.results lastObject];

    return object ? [self.convertor objectFromRLMObject:object] : nil;
}

- (NSObject *)objectAtIndex:(NSUInteger)index
{
    RLMObject *object = [self.results objectAtIndex:index];

    return object ? [self.convertor objectFromRLMObject:object] : nil;
}

- (OCTArray *)sortedObjectsUsingDescriptors:(NSArray *)array
{
    NSMutableArray *rlmArray = [NSMutableArray new];
    for (OCTSortDescriptor *descriptor in array) {
        RLMSortDescriptor *rlmDescriptor = [self.convertor rlmSortDescriptorFromDescriptor:descriptor];

        if (rlmDescriptor) {
            [rlmArray addObject:rlmDescriptor];
        }
    }

    RLMResults *results = [self.results sortedResultsUsingDescriptors:rlmArray];

    return [[OCTArray alloc] initWithRLMResults:results convertor:self.convertor];
}

- (void)enumerateObjectsUsingBlock:(void (^)(NSObject *obj, NSUInteger idx, BOOL *stop))block
{
    NSParameterAssert(block);

    BOOL stop = NO;
    for (NSUInteger index = 0; index < self.results.count; index++) {
        RLMObject *rlmObject = [self.results objectAtIndex:index];
        NSObject *object = [self.convertor objectFromRLMObject:rlmObject];

        block(object, index, &stop);

        if (stop) {
            break;
        }
    }
}

@end
