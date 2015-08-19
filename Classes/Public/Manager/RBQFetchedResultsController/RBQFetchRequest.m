//
//  RBQFetchRequest.m
//  RBQFetchedResultsControllerTest
//
//  Created by Adam Fish on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import "RBQFetchRequest.h"
#import "RLMObject+Utilities.h"

#pragma mark - Public Functions

NSString *RBQClassNameForRealmEntityName(NSString *entityName)
{
    Class objcClass = NSClassFromString(entityName);

    if (objcClass) {
        return entityName;
    }

    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];

    NSString *swiftClassName = [NSString stringWithFormat:@"%@.%@", appName, entityName];

    return swiftClassName;
}

BOOL RBQIsSwiftRealmClassName(NSString *className)
{
    return [className rangeOfString:@"."].location != NSNotFound;
}

NSString *RBQRealmClassNameFromSwiftClassName(NSString *className)
{
    return [className substringFromIndex:[className rangeOfString:@"."].location + 1];
}

@interface RBQFetchRequest ()

@property (strong, nonatomic) RLMRealm *realmForMainThread; // Improves scroll performance

@end

@implementation RBQFetchRequest
@synthesize entityName = _entityName,
realmPath = _realmPath,
inMemoryRealmId = _inMemoryRealmId;

#pragma mark - Public Class

+ (RBQFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
                                        inRealm:(RLMRealm *)realm
                                      predicate:(NSPredicate *)predicate
{
    RBQFetchRequest *fetchRequest = [[RBQFetchRequest alloc] initWithEntityName:entityName
                                                                        inRealm:realm];
    fetchRequest.predicate = predicate;

    return fetchRequest;
}

+ (RBQFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
                                  inMemoryRealm:(RLMRealm *)inMemoryRealm
                                      predicate:(NSPredicate *)predicate
{
    RBQFetchRequest *fetchRequest = [[RBQFetchRequest alloc] initWithEntityName:entityName
                                                                  inMemoryRealm:inMemoryRealm];
    fetchRequest.predicate = predicate;

    return fetchRequest;
}

#pragma mark - Public Instance

- (instancetype)initWithEntityName:(NSString *)entityName
                     inMemoryRealm:(RLMRealm *)inMemoryRealm
{
    self = [super init];

    if (self) {
        // Returns the appropriate class name for Obj-C or Swift
        _entityName = RBQClassNameForRealmEntityName(entityName);
        _inMemoryRealmId = inMemoryRealm.path.lastPathComponent;
        _realmPath = inMemoryRealm.path;
    }

    return self;
}

- (instancetype)initWithEntityName:(NSString *)entityName
                           inRealm:(RLMRealm *)realm
{
    self = [super init];

    if (self) {
        // Returns the appropriate class name for Obj-C or Swift
        _entityName = RBQClassNameForRealmEntityName(entityName);
        _realmPath = realm.path;
    }

    return self;
}

- (RLMResults *)fetchObjects
{
    return [self fetchObjectsInRealm:self.realm];
}

- (RLMResults *)fetchObjectsInRealm:(RLMRealm *)realm
{
    RLMResults *fetchResults = [NSClassFromString(self.entityName) allObjectsInRealm:realm];

    // If we have a predicate use it
    if (self.predicate) {
        fetchResults = [fetchResults objectsWithPredicate:self.predicate];
    }

    // If we have sort descriptors then use them
    if (self.sortDescriptors.count > 0) {
        fetchResults = [fetchResults sortedResultsUsingDescriptors:self.sortDescriptors];
    }

    return fetchResults;
}

- (BOOL)evaluateObject:(RLMObject *)object
{
    // If we have a predicate, use it
    if (self.predicate) {
        return [self.predicate evaluateWithObject:object];
    }

    // Verify the class name of object match the entity name of fetch request
    NSString *className = [RLMObject classNameForObject:object];

    BOOL sameEntity = [className isEqualToString:self.entityName];

    return sameEntity;
}

#pragma mark - Getter

- (RLMRealm *)realm
{
    if (self.inMemoryRealmId) {
        return [RLMRealm inMemoryRealmWithIdentifier:self.inMemoryRealmId];
    }

    if ([NSThread isMainThread] &&
        ! self.realmForMainThread) {

        self.realmForMainThread = [RLMRealm realmWithPath:self.realmPath];
    }

    if ([NSThread isMainThread]) {

        return self.realmForMainThread;
    }

    return [RLMRealm realmWithPath:self.realmPath];
}

#pragma mark - Hash

- (NSUInteger)hash
{
    if (self.predicate &&
        self.sortDescriptors) {

        NSUInteger sortHash = 1;

        for (RLMSortDescriptor *sortDescriptor in self.sortDescriptors) {
            sortHash = sortHash ^ sortDescriptor.hash;
        }

        return self.predicate.hash ^ sortHash ^ self.entityName.hash;
    }
    else if (self.predicate &&
             self.entityName) {
        return self.predicate.hash ^ self.entityName.hash;
    }
    else {
        return [super hash];
    }
}

@end
