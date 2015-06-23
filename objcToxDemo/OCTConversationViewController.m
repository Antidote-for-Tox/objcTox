//
//  OCTConversationViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 23.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <BlocksKit/UIBarButtonItem+BlocksKit.h>

#import "OCTConversationViewController.h"
#import "RBQFetchedResultsController.h"
#import "OCTChat.h"
#import "OCTMessageAbstract.h"

@interface OCTConversationViewController () <RBQFetchedResultsControllerDelegate>

@property (strong, nonatomic) OCTChat *chat;
@property (strong, nonatomic) RBQFetchedResultsController *resultsController;

@end

@implementation OCTConversationViewController

- (instancetype)initWithManager:(OCTManager *)manager chat:(OCTChat *)chat
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    _chat = chat;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chat.uniqueIdentifier == %@", chat.uniqueIdentifier];
    RBQFetchRequest *fetchRequest = [self.manager fetchRequestForType:OCTFetchRequestTypeMessageAbstract withPredicate:predicate];

    _resultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                sectionNameKeyPath:nil
                                                                         cacheName:nil];
    _resultsController.delegate = self;
    [_resultsController performFetch];

    self.title = [NSString stringWithFormat:@"%@", chat.uniqueIdentifier];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak OCTConversationViewController *weakSelf = self;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              bk_initWithBarButtonSystemItem:UIBarButtonSystemItemAdd handler:^(id handler) {
        [weakSelf showSendDialog];
    }];
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -  UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.resultsController numberOfRowsForSectionIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTMessageAbstract *message = [self.resultsController objectAtIndexPath:indexPath];

    cell.textLabel.text = [message description];

    return cell;
}

#pragma mark -  RBQFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void) controller:(RBQFetchedResultsController *)controller
    didChangeObject:(RBQSafeRealmObject *)anObject
        atIndexPath:(NSIndexPath *)indexPath
      forChangeType:(NSFetchedResultsChangeType)type
       newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controllerDidChangeContent:(RBQFetchedResultsController *)controller
{
    @try {
        [self.tableView endUpdates];
    }
    @catch (NSException *ex) {
        [self.resultsController reset];
        [self.tableView reloadData];
    }
}

#pragma mark -  Private

- (void)showSendDialog
{
    __weak OCTConversationViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        [sheet bk_addButtonWithTitle:@"Send message" handler:^{
            [weakSelf sendMessage];
        }];

        [sheet bk_addButtonWithTitle:@"Call friend" handler:^{
            [weakSelf callFriend];
        }];

        [sheet bk_addButtonWithTitle:@"Send call controls"
                             handler:^{
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
    }];
}

- (void)showSendControlDialog
{
    __weak OCTConversationViewController *weakSelf = self;
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

- (void)sendMessage
{
    UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:@"Send message" message:nil];

    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *messageField = [alert textFieldAtIndex:0];
    messageField.placeholder = @"Message";

    __weak OCTConversationViewController *weakSelf = self;
    [alert bk_addButtonWithTitle:@"OK" handler:^{
        [weakSelf.manager.chats sendMessageToChat:weakSelf.chat text:messageField.text type:OCTToxMessageTypeNormal error:nil];
        [weakSelf.tableView reloadData];
    }];

    [alert bk_setCancelButtonWithTitle:@"Cancel" handler:nil];

    [alert show];
}

#pragma mark - Call methods

- (void)callFriend
{
    NSError *error;
    [self.manager.calls callToChat:self.chat enableAudio:YES enableVideo:NO error:&error];

    NSLog(@"%@ Error %@", self, error.localizedDescription);
    NSLog(@"%@ Reason: %@", self, error.localizedFailureReason);
}

- (void)cancel
{
    OCTCall *call = [self.manager.calls.calls callWithChat:self.chat];

    NSError *error;
    if (! [self.manager.calls sendCallControl:OCTToxAVCallControlCancel toCall:call error:&error]) {
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
    OCTCall *call = [self.manager.calls.calls callWithChat:self.chat];
    [self.manager.calls sendCallControl:OCTToxAVCallControlPause toCall:call error:nil];
}

- (void)resume
{
    OCTCall *call = [self.manager.calls.calls callWithChat:self.chat];
    [self.manager.calls sendCallControl:OCTToxAVCallControlResume toCall:call error:nil];
}

- (void)muteFriend
{
    OCTCall *call = [self.manager.calls.calls callWithChat:self.chat];
    [self.manager.calls sendCallControl:OCTToxAVCallControlMuteAudio toCall:call error:nil];
}

- (void)unmuteFriend
{
    OCTCall *call = [self.manager.calls.calls callWithChat:self.chat];
    [self.manager.calls sendCallControl:OCTToxAVCallControlUnmuteAudio toCall:call error:nil];
}
@end
