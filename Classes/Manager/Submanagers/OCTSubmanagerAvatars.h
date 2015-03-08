//
//  OCTSubmanagerAvatars.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTManagerAvatarsProtocol.h"
#import "OCTToxDelegate.h"

@interface OCTSubmanagerAvatars : NSObject <OCTManagerAvatarsProtocol, OCTToxDelegate>

- (instancetype)initWithTox:(OCTTox *)tox;

@end
