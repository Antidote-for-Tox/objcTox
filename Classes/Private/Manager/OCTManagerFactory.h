//
//  OCTManagerFactory.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 10/08/16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OCTManagerConfiguration;
@class OCTManager;

@interface OCTManagerFactory : NSObject

+ (void)managerWithConfiguration:(OCTManagerConfiguration *)configuration
                 encryptPassword:(nonnull NSString *)encryptPassword
                    successBlock:(void (^)(OCTManager *manager))successBlock
                    failureBlock:(void (^)(NSError *error))failureBlock;

@end

NS_ASSUME_NONNULL_END
