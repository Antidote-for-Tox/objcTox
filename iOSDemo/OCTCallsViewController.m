//
//  OCTCallsViewController.m
//  objcTox
//
//  Created by Chuong Vu on 6/26/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <BlocksKit/UIBarButtonItem+BlocksKit.h>

#import "OCTCallsViewController.h"
#import "OCTSubmanagerCalls.h"
#import "OCTSubmanagerObjects.h"
#import "OCTCall.h"
#import "OCTVideoViewController.h"

@interface OCTCallsViewController ()

@property (strong, nonatomic) RLMResults<OCTCall *> *calls;
@property (strong, nonatomic) RLMNotificationToken *callsNotificationToken;
@property (strong, nonatomic) OCTCall *selectedCall;

@end

@implementation OCTCallsViewController

#pragma mark - Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    _calls = [self.manager.objects objectsForType:OCTFetchRequestTypeCall predicate:nil];

    self.title = @"Calls";

    return self;
}

- (void)dealloc
{
    [self.callsNotificationToken stop];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;

    self.callsNotificationToken = [self.calls addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *error) {
        if (error) {
            NSLog(@"Failed to open Realm on background worker: %@", error);
            return;
        }

        UITableView *tableView = weakSelf.tableView;

        // Initial run of the query will pass nil for the change information
        if (! changes) {
            [tableView reloadData];
            return;
        }

        // Query results have changed, so apply them to the UITableView
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:[changes deletionsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView insertRowsAtIndexPaths:[changes insertionsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView reloadRowsAtIndexPaths:[changes modificationsInSection:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
    }];
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedCall = self.calls[indexPath.row];

    [self showActionDialog];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTCall *call = self.calls[indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@"Call\n"
                           @"Chat identifier %@\n"
                           @"call status: %ld\n"
                           @"callDuration: %f\n"
                           @"friend sending audio: %d\n"
                           @"friend receiving audio: %d\n"
                           @"friend sending video: %d\n"
                           @"friend receiving Video: %d\n",
                           call.chat.uniqueIdentifier, (long)call.status, call.callDuration, call.friendSendingAudio, call.friendAcceptingAudio,
                           call.friendSendingVideo, call.friendAcceptingVideo];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.calls.count;
}

#pragma mark - Private

- (void)showActionDialog
{
    __weak OCTCallsViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        [sheet bk_addButtonWithTitle:@"Send call controls" handler:^{
            [weakSelf showSendControlDialog];
        }];

        [sheet bk_addButtonWithTitle:@"Mute/Unmute Mic" handler:^{
            [weakSelf toggleMuteMic];
        }];

        [sheet bk_addButtonWithTitle:@"Use speaker phone" handler:^{
            [weakSelf useSpeaker];
        }];

        [sheet bk_addButtonWithTitle:@"Use default speakers" handler:^{
            [weakSelf useDefaultSpeaker];
        }];

        [sheet bk_addButtonWithTitle:@"Show video" handler:^{
            [weakSelf showVideo];
        }];
    }];

}

- (void)showSendControlDialog
{
    __weak OCTCallsViewController *weakSelf = self;

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Call control"
                                                                             message:@"Pick call control to send to friend"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *pauseAction = [UIAlertAction actionWithTitle:@"Pause"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {[weakSelf pause];
    }];

    UIAlertAction *resumeAction = [UIAlertAction actionWithTitle:@"Resume"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {[weakSelf resume];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"End/Reject Call"
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {[weakSelf cancel];
    }];

    UIAlertAction *muteAction = [UIAlertAction actionWithTitle:@"Mute Audio"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {[weakSelf muteFriend];
    }];

    UIAlertAction *unmuteAction = [UIAlertAction actionWithTitle:@"Unmute Audio"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {[weakSelf unmuteFriend];
    }];

    [alertController addAction:pauseAction];
    [alertController addAction:resumeAction];
    [alertController addAction:cancelAction];
    [alertController addAction:muteAction];
    [alertController addAction:unmuteAction];

    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Call methods

- (void)cancel
{
    NSError *error;
    if (! [self.manager.calls sendCallControl:OCTToxAVCallControlCancel toCall:self.selectedCall error:&error]) {
        NSLog(@"%@ Error %@", self, error.localizedDescription);
        NSLog(@"%@ Reason: %@", self, error.localizedFailureReason);
    }
}

- (void)useSpeaker
{
    [self.manager.calls routeAudioToSpeaker:YES error:nil];
}

- (void)useDefaultSpeaker
{
    [self.manager.calls routeAudioToSpeaker:NO error:nil];
}

- (void)toggleMuteMic
{
    BOOL currentStatus = self.manager.calls.enableMicrophone;
    self.manager.calls.enableMicrophone = ! currentStatus;
}

- (void)pause
{
    [self.manager.calls sendCallControl:OCTToxAVCallControlPause toCall:self.selectedCall error:nil];
}

- (void)resume
{
    [self.manager.calls sendCallControl:OCTToxAVCallControlResume toCall:self.selectedCall error:nil];
}

- (void)muteFriend
{
    [self.manager.calls sendCallControl:OCTToxAVCallControlMuteAudio toCall:self.selectedCall error:nil];
}

- (void)unmuteFriend
{
    [self.manager.calls sendCallControl:OCTToxAVCallControlUnmuteAudio toCall:self.selectedCall error:nil];
}

- (void)showVideo
{
    [self.manager.calls enableVideoSending:YES forCall:self.selectedCall error:nil];

    OCTVideoViewController *videoViewController = [[OCTVideoViewController alloc] initWithCallManager:self.manager.calls call:self.selectedCall];
    videoViewController.modalInPopover = YES;
    videoViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;

    [self presentViewController:videoViewController animated:YES completion:nil];
}

@end
