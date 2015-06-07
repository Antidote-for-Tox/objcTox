//
//  OCTCallSubmanager.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerCalls+Private.h"
#import "OCTToxAV.h"
#import "OCTAudioEngine.h"

@interface OCTSubmanagerCalls () <OCTToxAVDelegate>

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;

@end

@implementation OCTSubmanagerCalls : NSObject

- (instancetype)initWithTox:(OCTTox *)tox
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _toxAV = [[OCTToxAV alloc] initWithTox:tox error:nil];
    _toxAV.delegate = self;

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

- (BOOL)togglePause:(BOOL)pause forCall:(OCTCall *)call error:(NSError **)error
{
    return NO;
}

- (BOOL)endCall:(OCTCall *)call error:(NSError **)error
{
    return NO;
}

- (BOOL)toggleMute:(BOOL)mute forCall:(OCTCall *)call error:(NSError **)error
{
    return NO;
}

- (BOOL)togglePauseVideo:(BOOL)pause forCall:(OCTCall *)call error:(NSError **)error
{
    return NO;
}

- (UIView *)videoFeed
{
    return nil;
}

- (void)setAudioBitrate:(int)bitrate forCall:(OCTCall *)call error:(NSError **)error
{
    // To Do
}

- (void)setVideoBitrate:(int)bitrate forCall:(OCTCall *)call error:(NSError **)error
{
    // To Do
}

#pragma mark OCTToxAV delegate methods


@end
