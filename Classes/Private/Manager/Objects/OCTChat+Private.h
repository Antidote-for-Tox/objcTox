//
//  OCTChat+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 27.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTChat.h"
#import "OCTDBChat.h"
#import "OCTDBManager.h"

@interface OCTChat (Private)

@property (strong, nonatomic, readwrite) NSArray *friends;
@property (strong, nonatomic, readwrite) OCTMessageAbstract *lastMessage;

@property (strong, nonatomic) OCTDBChat *dbChat;
@property (weak, nonatomic) OCTDBManager *dbManager;

@end
