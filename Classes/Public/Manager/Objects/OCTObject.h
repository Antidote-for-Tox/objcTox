//
//  OCTObject.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 22.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Realm/Realm.h>

/**
 * Please note that all properties of this object are readonly.
 * You can change some of them only with appropriate method in submanagers.
 */
@interface OCTObject : RLMObject

/**
 * The unique identifier of object.
 */
@property NSString *uniqueIdentifier;

/**
 * Returns a string that represents the contents of the receiving class.
 */
- (NSString *)description;

/**
 * Returns a Boolean value that indicates whether the receiver and a given object are equal.
 */
- (BOOL)isEqual:(id)object;

/**
 * Returns an integer that can be used as a table address in a hash table structure.
 */
- (NSUInteger)hash;

@end
