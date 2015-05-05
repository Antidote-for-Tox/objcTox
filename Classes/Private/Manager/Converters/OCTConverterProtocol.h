//
//  OCTConverterProtocol.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTSortDescriptor.h"
#import "RLMObject.h"
#import "RLMArray.h"

@protocol OCTConverterProtocol <NSObject>

@property (strong, nonatomic, readonly) NSString *objectClassName;

- (NSObject *)objectFromRLMObject:(RLMObject *)rlmObject;

- (RLMSortDescriptor *)rlmSortDescriptorFromDescriptor:(OCTSortDescriptor *)descriptor;

@end
