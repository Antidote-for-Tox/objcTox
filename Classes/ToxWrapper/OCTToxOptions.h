//
//  OCTToxOptions.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTToxConstants.h"

@interface OCTToxOptions : NSObject <NSCopying>

@property (assign, nonatomic) BOOL IPv6Enabled;
@property (assign, nonatomic) BOOL UDPEnabled;

@property (assign, nonatomic) OCTToxProxyType proxyType;
@property (strong, nonatomic) NSString *proxyAddress;
@property (assign, nonatomic) uint16_t proxyPort;

@end
