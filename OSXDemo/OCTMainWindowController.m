//
//  OCTMainWindowController.m
//  objcTox
//
//  Created by Chuong Vu on 12/9/15.
//  Copyright © 2015 dvor. All rights reserved.
//

#import "OCTMainWindowController.h"
#import "OCTBootStrapViewController.h"
#import "OCTManagerConfiguration.h"
#import "OCTManager.h"
#import "OCTSubmanagerBootstrap.h"
#import "OCTUserViewController.h"
#import "OCTFriendsViewController.h"

@interface OCTMainWindowController () <OCTBootStrapViewDelegate>

@property (weak) IBOutlet NSView *mainView;
@property (strong, nonatomic) NSViewController *currentViewController;
@property (strong, nonatomic) NSViewController *userViewController;
@property (strong, nonatomic) NSViewController *friendUserViewController;

@property (strong, nonatomic) OCTManagerConfiguration *configuration;
@property (strong, nonatomic) OCTManager *manager;
@property (weak) IBOutlet NSTabView *tabView;

@end

@implementation OCTMainWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.configuration = [OCTManagerConfiguration defaultConfiguration];
    self.tabView.hidden = YES;

    [self setupBootstrapViewController];
}

- (void)setupBootstrapViewController
{
    OCTBootStrapViewController *bootstrapVC = [[OCTBootStrapViewController alloc]
                                               initWithConfiguration:self.configuration];
    bootstrapVC.delegate = self;

    self.currentViewController = bootstrapVC;
    [self.mainView addSubview:self.currentViewController.view];
    [self.currentViewController.view setFrame:self.mainView.bounds];
}

#pragma mark - Bootstrap delegate

- (void)didBootStrap:(OCTBootStrapViewController *)controller
{
    [self.currentViewController.view removeFromSuperview];
    self.currentViewController = nil;
    self.manager = [[OCTManager alloc] initWithConfiguration:self.configuration error:nil];
    [self.manager.bootstrap addPredefinedNodes];
    [self.manager.bootstrap bootstrap];

    self.tabView.hidden = NO;

    [self setupTabControllers];
}

#pragma mark - Private

- (void)setupTabControllers
{
    NSTabViewItem *userViewItem = [self.tabView tabViewItemAtIndex:0];
    self.userViewController = [[OCTUserViewController alloc] initWithManager:self.manager.user];
    userViewItem.view = self.userViewController.view;

    NSTabViewItem *friendViewItem = [self.tabView tabViewItemAtIndex:1];
    self.friendUserViewController = [[OCTFriendsViewController alloc] initWithManager:self.manager];
    friendViewItem.view = self.friendUserViewController.view;
}

@end
