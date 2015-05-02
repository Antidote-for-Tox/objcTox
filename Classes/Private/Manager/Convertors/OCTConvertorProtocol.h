//
//  OCTConvertorProtocol.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTSortDescriptor.h"
#import "RLMObject.h"
#import "RLMArray.h"

@protocol OCTConvertorProtocol <NSObject>

@property (strong, nonatomic, readonly) NSString *objectClassName;

- (NSObject *)objectFromRLMObject:(RLMObject *)rlmObject;
- (RLMObject *)rlmObjectFromObject:(NSObject *)object;

- (RLMSortDescriptor *)rlmSortDescriptorFromDescriptor:(OCTSortDescriptor *)descriptor;

@end
