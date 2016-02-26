//
//  OCTSubmanagerBootstrap.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 05/08/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerBootstrap+Private.h"
#import "OCTPredefined.h"
#import "OCTNode.h"
#import "OCTTox.h"
#import "DDLog.h"
#import "OCTRealmManager.h"
#import "OCTSettingsStorageObject.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

static const NSTimeInterval kDidConnectDelay = 10.0;
static const NSTimeInterval kIterationTime = 5.0;
static const NSUInteger kNodesPerIteration = 4;

@interface OCTSubmanagerBootstrap ()

@property (strong, nonatomic) NSMutableSet *addedNodes;

@property (assign, nonatomic) BOOL isBootstrapping;

@property (strong, nonatomic) NSObject *bootstrappingLock;

@property (assign, nonatomic) NSTimeInterval didConnectDelay;
@property (assign, nonatomic) NSTimeInterval iterationTime;

@end

@implementation OCTSubmanagerBootstrap
@synthesize dataSource = _dataSource;

#pragma mark -  Lifecycle

- (instancetype)init
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _addedNodes = [NSMutableSet new];
    _bootstrappingLock = [NSObject new];

    _didConnectDelay = kDidConnectDelay;
    _iterationTime = kIterationTime;

    return self;
}

#pragma mark -  Public

- (void)addNodeWithHost:(NSString *)host port:(OCTToxPort)port publicKey:(NSString *)publicKey
{
    OCTNode *node = [[OCTNode alloc] initWithHost:host port:port publicKey:publicKey];

    @synchronized(self.addedNodes) {
        [self.addedNodes addObject:node];
    }
}

- (void)addPredefinedNodes
{
    NSString *file = [[self objcToxBundle] pathForResource:@"nodes" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:file];

    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSAssert(dictionary, @"Nodes json file is corrupted.");

    for (NSDictionary *node in dictionary[@"nodes"]) {
        NSString *host = node[@"ipv4"];
        OCTToxPort port = [node[@"port"] unsignedShortValue];
        NSString *publicKey = node[@"public_key"];

        NSAssert(host, @"Nodes json file is corrupted");
        NSAssert(port > 0, @"Nodes json file is corrupted");
        NSAssert(publicKey, @"Nodes json file is corrupted");

        [self addNodeWithHost:host port:port publicKey:publicKey];
    }
}

- (void)bootstrap
{
    @synchronized(self.bootstrappingLock) {
        if (self.isBootstrapping) {
            DDLogWarn(@"%@: bootstrap method called while already bootstrapping", self);
            return;
        }
        self.isBootstrapping = YES;
    }

    DDLogVerbose(@"%@: bootstrapping with %lu nodes", self, (unsigned long)self.addedNodes.count);

    OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];

    if (realmManager.settingsStorage.bootstrapDidConnect) {
        DDLogVerbose(@"%@: did connect before, waiting %g seconds", self, self.didConnectDelay);
        [self tryToBootstrapAfter:self.didConnectDelay];
    }
    else {
        [self tryToBootstrap];
    }
}

- (BOOL)addTCPRelayWithHost:(NSString *)host
                       port:(OCTToxPort)port
                  publicKey:(NSString *)publicKey
                      error:(NSError **)error
{
    return [[self.dataSource managerGetTox] addTCPRelayWithHost:host port:port publicKey:publicKey error:error];
}

#pragma mark -  Private

- (void)tryToBootstrapAfter:(NSTimeInterval)after
{
    __weak OCTSubmanagerBootstrap *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, after * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        __strong OCTSubmanagerBootstrap *strongSelf = weakSelf;

        if (! strongSelf) {
            DDLogInfo(@"OCTSubmanagerBootstrap is dead, seems that OCTManager was killed, quiting.");
            return;
        }

        [strongSelf tryToBootstrap];
    });
}

- (void)tryToBootstrap
{
    if ([self.dataSource managerIsToxConnected]) {
        DDLogInfo(@"%@: trying to bootstrap... tox is connected, exiting", self);

        OCTRealmManager *realmManager = [self.dataSource managerGetRealmManager];
        [realmManager updateObject:realmManager.settingsStorage withBlock:^(OCTSettingsStorageObject *object) {
            object.bootstrapDidConnect = YES;
        }];

        [self finishBootstrapping];

        return;
    }

    NSArray *selectedNodes = [self selectedNodesForIteration];

    if (! selectedNodes.count) {
        DDLogInfo(@"%@: trying to bootstrap... no nodes left, exiting", self);
        [self finishBootstrapping];
        return;
    }

    DDLogInfo(@"%@: trying to bootstrap... picked %lu nodes", self, (unsigned long)selectedNodes.count);

    OCTTox *tox = [self.dataSource managerGetTox];

    for (OCTNode *node in selectedNodes) {
        [tox bootstrapFromHost:node.host port:node.port publicKey:node.publicKey error:nil];
    }

    [self tryToBootstrapAfter:self.iterationTime];
}

- (void)finishBootstrapping
{
    @synchronized(self.bootstrappingLock) {
        self.isBootstrapping = NO;
    }
}

- (NSArray *)selectedNodesForIteration
{
    NSMutableArray *allNodes;
    NSMutableArray *selectedNodes = [NSMutableArray new];

    @synchronized(self.addedNodes) {
        allNodes = [[self.addedNodes allObjects] mutableCopy];
    }

    while (allNodes.count && (selectedNodes.count < kNodesPerIteration)) {
        NSUInteger index = arc4random_uniform((u_int32_t)allNodes.count);

        [selectedNodes addObject:allNodes[index]];
        [allNodes removeObjectAtIndex:index];
    }

    @synchronized(self.addedNodes) {
        [self.addedNodes minusSet:[NSSet setWithArray:selectedNodes]];
    }

    return [selectedNodes copy];
}

- (NSBundle *)objcToxBundle
{
    NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
    NSBundle *objcToxBundle = [NSBundle bundleWithPath:[mainBundle pathForResource:@"objcTox" ofType:@"bundle"]];

    // objcToxBundle is used when installed with CocoaPods. If we run tests/demo app mainBundle would be used.
    return objcToxBundle ?: mainBundle;
}

@end
