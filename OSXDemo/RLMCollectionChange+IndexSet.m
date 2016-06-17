//
//  RLMCollectionChange+IndexSet.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 06/05/16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "RLMCollectionChange+IndexSet.h"

@implementation RLMCollectionChange (IndexSet)

#pragma mark -  Public

- (NSIndexSet *)deletionsSet
{
    return [self indexSetFromNumbersArray:[self deletions]];
}

- (NSIndexSet *)insertionsSet
{
    return [self indexSetFromNumbersArray:[self insertions]];
}

- (NSIndexSet *)modificationsSet
{
    return [self indexSetFromNumbersArray:[self modifications]];
}

#pragma mark -  Private

- (NSIndexSet *)indexSetFromNumbersArray:(NSArray<NSNumber *> *)numbersArray
{
    NSMutableIndexSet *set = [NSMutableIndexSet new];

    for (NSNumber *number in numbersArray) {
        [set addIndex:number.integerValue];
    }

    return [set copy];
}

@end
