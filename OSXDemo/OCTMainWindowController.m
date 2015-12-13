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

const NSInteger kUserTag = 0;
const NSInteger kFriendsTag = 1;
const NSInteger kChatsTag = 2;

@interface OCTMainWindowController () <OCTBootStrapViewDelegate>

@property (weak) IBOutlet NSView *mainView;
@property (weak) IBOutlet NSPopUpButton *dropDownButton;
@property (strong, nonatomic) NSViewController *currentViewController;

@property (strong, nonatomic) OCTManagerConfiguration *configuration;
@property (strong, nonatomic) OCTManager *manager;

@end

@implementation OCTMainWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];

    self.configuration = [OCTManagerConfiguration defaultConfiguration];
    self.dropDownButton.hidden = YES;

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

- (IBAction)changeViewSelected:(NSPopUpButtonCell *)sender
{
    [self changeViewControllerForTag:sender.selectedItem.tag];
}


#pragma mark - Bootstrap delegate

- (void)didBootStrap:(OCTBootStrapViewController *)controller
{
    [self.currentViewController.view removeFromSuperview];
    self.currentViewController = nil;
    self.manager = [[OCTManager alloc] initWithConfiguration:self.configuration error:nil];
    [self.manager.bootstrap addPredefinedNodes];
    [self.manager.bootstrap bootstrap];
    self.dropDownButton.hidden = NO;
    [self.dropDownButton selectItemAtIndex:kUserTag];
    [self changeViewControllerForTag:kUserTag];
}

#pragma mark - Private

- (void)changeViewControllerForTag:(NSInteger)tag
{
    if (self.currentViewController) {
        [self.currentViewController.view removeFromSuperview];
        self.currentViewController = nil;
    }

    switch (tag) {
        case kUserTag:
            [self switchToUsersWindow];
            break;
        case kChatsTag:
            break;
        case kFriendsTag:
            [self switchToFriendWindow];
            break;
    }
}

- (void)switchToUsersWindow
{
    OCTUserViewController *userViewController = [[OCTUserViewController alloc] initWithManager:self.manager.user];
    self.currentViewController = userViewController;
    [self.mainView addSubview:self.currentViewController.view];
    self.currentViewController.view.frame = self.mainView.bounds;
}

- (void)switchToChatWindow
{}

- (void)switchToFriendWindow
{
    OCTFriendsViewController *friendsViewController = [[OCTFriendsViewController alloc] initWithManager:self.manager];
    self.currentViewController = friendsViewController;
    [self.mainView addSubview:self.currentViewController.view];

    NSView *view = self.currentViewController.view;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(view);
    [self.mainView addConstraints:[NSLayoutConstraint
                                              constraintsWithVisualFormat:@"V:|[view]|"
                                                                options:0
                                                                metrics:nil
                                                                views:viewsDictionary]];

    [self.mainView addConstraints:[NSLayoutConstraint
                                              constraintsWithVisualFormat:@"H:|[view]|"
                                              options:0
                                              metrics:nil
                                              views:viewsDictionary]];

    self.currentViewController.view.frame = self.mainView.bounds;
}

@end
