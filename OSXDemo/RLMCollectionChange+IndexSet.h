//
//  RLMCollectionChange+IndexSet.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 06/05/16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface RLMCollectionChange (IndexSet)

- (NSIndexSet *)deletionsSet;
- (NSIndexSet *)insertionsSet;
- (NSIndexSet *)modificationsSet;

@end
