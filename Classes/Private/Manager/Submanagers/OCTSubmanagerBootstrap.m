//
//  OCTSubmanagerBootstrap.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 05/08/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerBootstrap+Private.h"
#import "OCTPredefinedNodes.h"
#import "OCTNode.h"
#import "OCTTox.h"
#import "OCTSettingsStorageProtocol.h"
#import "DDLog.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_VERBOSE

static const NSTimeInterval kDidConnectDelay = 10.0;
static const NSTimeInterval kIterationTime = 5.0;
static const NSUInteger kNodesPerIteration = 4;

static NSString *const kOCTSubmanagerBootstrapDidConnectKey = @"kOCTSubmanagerBootstrapDidConnectKey";

@interface OCTSubmanagerBootstrap ()

@property (strong, nonatomic) NSMutableSet *addedNodes;

@property (assign, nonatomic) BOOL isBootstrapping;

@property (strong, nonatomic) NSObject *nodesLock;
@property (strong, nonatomic) NSObject *bootstrappingLock;

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
    _nodesLock = [NSObject new];
    _bootstrappingLock = [NSObject new];

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
    for (NSArray *nodeArray in OCTPredefinedNodes()) {
        NSNumber *port = nodeArray[1];
        [self addNodeWithHost:nodeArray[0] port:port.unsignedShortValue publicKey:nodeArray[2]];
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

    NSNumber *didConnect = [[self.dataSource managerGetSettingsStorage] objectForKey:kOCTSubmanagerBootstrapDidConnectKey];

    if (didConnect.boolValue) {
        DDLogVerbose(@"%@: did connect before, waiting %g seconds", self, kDidConnectDelay);
        [self performSelector:@selector(tryToBootstrap) withObject:nil afterDelay:kDidConnectDelay];
    }
    else {
        [self tryToBootstrap];
    }
}

#pragma mark -  Private

- (void)tryToBootstrap
{
    if ([self.dataSource managerIsToxConnected]) {
        DDLogInfo(@"%@: trying to bootstrap... tox is connected, exiting", self);
        [[self.dataSource managerGetSettingsStorage] setObject:@(YES) forKey:kOCTSubmanagerBootstrapDidConnectKey];
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

    [self performSelector:@selector(tryToBootstrap) withObject:nil afterDelay:kIterationTime];
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

    return [selectedNodes copy];
}

@end
