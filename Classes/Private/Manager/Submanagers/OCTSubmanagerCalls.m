//
//  OCTCallSubmanager.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerCalls+Private.h"
#import "OCTToxAV.h"

@interface OCTSubmanagerCalls ()

@property (strong, nonatomic) OCTToxAV *toxAV;

@end

@implementation OCTSubmanagerCalls : NSObject

- (instancetype)initWithTox:(OCTTox *)tox
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _toxAV = [[OCTToxAV alloc] initWithTox:tox error:nil];

    return self;
}

- (OCTCall *)callToChat:(OCTChat *)chat enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo
{
    return nil;
}

- (BOOL)answerCall:(OCTCall *)call enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError **)error
{
    return NO;
}

@end
