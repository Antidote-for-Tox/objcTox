// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
