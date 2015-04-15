//
//  OCTSubmanagerDataSource.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCTTox;
@protocol OCTSettingsStorageProtocol;
@protocol OCTFileStorageProtocol;

@protocol OCTSubmanagerDataSource <NSObject>

- (OCTTox *)managerGetTox;
- (id<OCTSettingsStorageProtocol>)managerGetSettingsStorage;
- (id<OCTFileStorageProtocol>)managerGetFileStorage;

@end
