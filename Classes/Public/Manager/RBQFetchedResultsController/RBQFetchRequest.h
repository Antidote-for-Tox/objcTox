//
//  RBQFetchRequest.h
//  RBQFetchedResultsControllerTest
//
//  Created by Adam Fish on 1/2/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@class RBQFetchRequest;

/**
 *  Returns the actual class name for a Realm entity name
 *
 *  For Swift this will be in the form of BundleName.ClassName since this is the actual class name
 *
 *  @param entityName the Realm object name
 *
 *  @return the class name for use with NSClassFromString()
 */
extern NSString *RBQClassNameForRealmEntityName(NSString *entityName);

/**
 *  Verifies if the class name is a Swift class (i.e. BundleName.ClassName)
 *
 *  @param className the class of the Realm object
 *
 *  @return BOOL value if the class name is a Swift name
 */
extern BOOL RBQIsSwiftRealmClassName(NSString *className);

/**
 *  Retrieves only the Realm class name from a Swift class name
 *
 *  @param className the Swift class name
 *
 *  @return the Realm class name
 */
extern NSString *RBQRealmClassNameFromSwiftClassName(NSString *className);

/**
 *  This class is used by the RBQFetchedResultsController to represent the properties of the fetch. The RBQFetchRequest is specific to one RLMObject and uses an NSPredicate and array of RLMSortDescriptors to define the query.
 */
@interface RBQFetchRequest : NSObject

/**
 *  RLMObject class name for the fetch request
 *
 *  For Swift this will be in the form of BundleName.ClassName since this is the actual class name
 */
@property (nonatomic, readonly) NSString *entityName;

/**
 *  The Realm in which the entity for the fetch request is persisted.
 */
@property (nonatomic, readonly) RLMRealm *realm;

/**
 *  Path for the Realm associated with the fetch request
 */
@property (nonatomic, readonly) NSString *realmPath;

/**
 *  The identifier of the in-memory Realm.
 *
 *  @warning return nil if fetch request initialized without in-memory Realm
 */
@property (nonatomic, readonly) NSString *inMemoryRealmId;

/**
 *  Predicate supported by Realm
 *
 *  http://realm.io/docs/cocoa/0.89.2/#querying-with-predicates
 */
@property (nonatomic, strong) NSPredicate *predicate;

/**
 *  Array of RLMSortDescriptors
 *
 *  http://realm.io/docs/cocoa/0.89.2/#ordering-results
 */
@property (nonatomic, strong) NSArray *sortDescriptors;


/**
 *  Constructor method to create a fetch request for a given entity name in a specific Realm.
 *
 *  @param entityName Class name for the RLMObject
 *  @param realm      RLMRealm in which the RLMObject is persisted (if passing in-memory Realm, make sure to keep a strong reference elsewhere since fetch request only stores the path)
 *  @param predicate  NSPredicate that represents the search query
 *
 *  @return A new instance of RBQFetchRequest
 */
+ (RBQFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
                                        inRealm:(RLMRealm *)realm
                                      predicate:(NSPredicate *)predicate;

/**
 *  Constructor method to create a fetch request for a given entity name in an in-memory Realm.
 *
 *  @param entityName Class name for the RLMObject
 *  @param inMemoryRealm In-memory RLMRealm in which the RLMObject is persisted (caller must retain strong reference as fetch request does not)
 *  @param predicate  NSPredicate that represents the search query
 *
 *  @return A new instance of RBQFetchRequest
 */
+ (RBQFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
                                  inMemoryRealm:(RLMRealm *)inMemoryRealm
                                      predicate:(NSPredicate *)predicate;

/**
 *  Retrieve all the RLMObjects for this fetch request in its realm.
 *
 *  @return RLMResults for all the objects in the fetch request (not thread-safe).
 */
- (RLMResults *)fetchObjects;

/**
 *  Retrieve all the RLMObjects for this fetch request in the specified realm.
 *
 *  @param realm RLMRealm in which the RLMObjects are persisted
 *
 *  @return RLMResults for all the objects in the fetch request (not thread-safe).
 */
- (RLMResults *)fetchObjectsInRealm:(RLMRealm *)realm;

/**
 *  Should this object be in our fetch results?
 *
 *  Intended to be used by the RBQFetchedResultsController to evaluate incremental changes. For
 *  simple fetch requests this just evaluates the NSPredicate, but subclasses may have a more
 *  complicated implementaiton.
 *
 *  @param object Realm object of appropriate type
 *
 *  @return YES if performing fetch would include this object
 */
- (BOOL)evaluateObject:(RLMObject *)object;

/**
 *  Create RBQFetchRequest in RLMRealm instance with an entity name
 *
 *  @param entityName Class name for the RLMObject
 *  @param realm      RLMRealm in which the RLMObject is persisted
 *
 *  @return A new instance of RBQFetchRequest
 */
- (instancetype)initWithEntityName:(NSString *)entityName
                           inRealm:(RLMRealm *)realm;

@end
