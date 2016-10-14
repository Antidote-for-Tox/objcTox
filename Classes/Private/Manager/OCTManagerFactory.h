// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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
