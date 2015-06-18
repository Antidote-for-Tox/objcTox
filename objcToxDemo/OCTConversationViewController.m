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

@interface OCTConversationViewController () <OCTArrayDelegate>

@property (strong, nonatomic) OCTChat *chat;
@property (strong, nonatomic) OCTArray *allMessages;

@end

@implementation OCTConversationViewController

- (instancetype)initWithManager:(OCTManager *)manager chat:(OCTChat *)chat
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    _chat = chat;

    _allMessages = [manager.chats allMessagesInChat:chat];
    _allMessages.delegate = self;

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
    return self.allMessages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTMessageAbstract *message = [self.allMessages objectAtIndex:indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@"%@", message];

    return cell;
}

#pragma mark -  OCTArrayDelegate

- (void)OCTArrayWasUpdated:(OCTArray *)array
{
    [self.tableView reloadData];
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

        [sheet bk_addButtonWithTitle:@"End call" handler:^{
            [weakSelf endCall];
        }];

        [sheet bk_addButtonWithTitle:@"Mute/Unmute" handler:^{
            [weakSelf toggleMuteMic];
        }];
    }];
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

- (void)callFriend
{
    NSError *error;
    [self.manager.calls callToChat:self.chat enableAudio:YES enableVideo:NO error:&error];

    NSLog(@"%@ Error %@", self, error.localizedDescription);
    NSLog(@"%@ Reason: %@", self, error.localizedFailureReason);
}

- (void)endCall
{
    NSError *error;

    OCTCall *call = [self.manager.calls.calls callWithChat:self.chat];

    if (! [self.manager.calls endCall:call error:&error]) {
        NSLog(@"%@ Error %@", self, error.localizedDescription);
        NSLog(@"%@ Reason: %@", self, error.localizedFailureReason);
    }
}

- (void)toggleMuteMic
{
    BOOL currentStatus = self.manager.calls.enableMicrophone;
    self.manager.calls.enableMicrophone = ! currentStatus;
}

@end
