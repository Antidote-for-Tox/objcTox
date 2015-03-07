//
//  OCTSettingsStorageProtocol.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 07.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OCTSettingsStorageProtocol <NSObject>

@required

- (void)setObject:(id)object forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;

@end
