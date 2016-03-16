//
//  OCTLogging.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.03.16.
//  Copyright © 2016 dvor. All rights reserved.
//

#import "DDLog.h"
#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

#define OCTLogError(frmt, ...)   DDLogError((@"<%@ %p> " frmt), [self class], self, ## __VA_ARGS__)
#define OCTLogWarn(frmt, ...)    DDLogWarn((@"<%@ %p> " frmt), [self class], self, ## __VA_ARGS__)
#define OCTLogInfo(frmt, ...)    DDLogInfo((@"<%@ %p> " frmt), [self class], self, ## __VA_ARGS__)
#define OCTLogDebug(frmt, ...)   DDLogDebug((@"<%@ %p> " frmt), [self class], self, ## __VA_ARGS__)
#define OCTLogVerbose(frmt, ...) DDLogVerbose((@"<%@ %p> " frmt), [self class], self, ## __VA_ARGS__)
