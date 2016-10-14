// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "DDLog.h"
#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

#define OCTLogError(frmt, ...)   DDLogError((@"<%@ %p> " frmt), [self class], self, ## __VA_ARGS__)
#define OCTLogWarn(frmt, ...)    DDLogWarn((@"<%@ %p> " frmt), [self class], self, ## __VA_ARGS__)
#define OCTLogInfo(frmt, ...)    DDLogInfo((@"<%@ %p> " frmt), [self class], self, ## __VA_ARGS__)
#define OCTLogDebug(frmt, ...)   DDLogDebug((@"<%@ %p> " frmt), [self class], self, ## __VA_ARGS__)
#define OCTLogVerbose(frmt, ...) DDLogVerbose((@"<%@ %p> " frmt), [self class], self, ## __VA_ARGS__)

#define OCTLogCError(frmt, obj, ...)   DDLogCError((@"<%@ %p> " frmt), [obj class], obj, ## __VA_ARGS__)
#define OCTLogCWarn(frmt, obj, ...)    DDLogCWarn((@"<%@ %p> " frmt), [obj class], obj, ## __VA_ARGS__)
#define OCTLogCInfo(frmt, obj, ...)    DDLogCInfo((@"<%@ %p> " frmt), [obj class], obj, ## __VA_ARGS__)
#define OCTLogCDebug(frmt, obj, ...)   DDLogCDebug((@"<%@ %p> " frmt), [obj class], obj, ## __VA_ARGS__)
#define OCTLogCVerbose(frmt, obj, ...) DDLogCVerbose((@"<%@ %p> " frmt), [obj class], obj, ## __VA_ARGS__)

#define OCTLogCCError(frmt, ...)   DDLogCError((frmt), ## __VA_ARGS__)
#define OCTLogCCWarn(frmt, ...)    DDLogCWarn((frmt), ## __VA_ARGS__)
#define OCTLogCCInfo(frmt, ...)    DDLogCInfo((frmt), ## __VA_ARGS__)
#define OCTLogCCDebug(frmt, ...)   DDLogCDebug((frmt), ## __VA_ARGS__)
#define OCTLogCCVerbose(frmt, ...) DDLogCVerbose((frmt), ## __VA_ARGS__)
