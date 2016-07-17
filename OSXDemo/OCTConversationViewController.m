//
//  OCTConversationViewController.m
//  objcTox
//
//  Created by Chuong Vu on 12/20/15.
//  Copyright © 2015 dvor. All rights reserved.
//

#import "OCTConversationViewController.h"
#import "OCTSubmanagerObjects.h"
#import "OCTSubmanagerChats.h"
#import "OCTFriend.h"
#import "OCTChat.h"
#import "OCTMessageAbstract.h"
#import "OCTSubmanagerUser.h"
#import "OCTSubmanagerCalls.h"
#import "OCTSubmanagerFiles.h"
#import "OCTMessageText.h"
#import "RLMCollectionChange+IndexSet.h"

static NSString *const kCellIdent = @"cellIdent";

@interface OCTConversationViewController () <NSTableViewDataSource,
                                             NSTableViewDelegate,
                                             NSTextFieldDelegate>

@property (weak) IBOutlet NSTableView *chatsViewController;
@property (weak, nonatomic) OCTManager *manager;

@property (strong, nonatomic) RLMResults<OCTChat *> *allChats;
@property (strong, nonatomic) RLMNotificationToken *allChatsNotificationToken;
@property (strong, nonatomic) RLMResults<OCTChat *> *conversationMessages;
@property (strong, nonatomic) RLMNotificationToken *conversationMessagesNotificationToken;

@property (weak) IBOutlet NSTableView *chatsTableView;
@property (weak) IBOutlet NSTableView *conversationTableView;

@end

@implementation OCTConversationViewController

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _manager = manager;

    _allChats = [self.manager.objects objectsForType:OCTFetchRequestTypeChat predicate:nil];
    _conversationMessages = nil;

    return self;
}

- (void)dealloc
{
    [self.allChatsNotificationToken stop];
    [self.conversationMessagesNotificationToken stop];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;

    self.allChatsNotificationToken = [self.allChats addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *error) {
        if (error) {
            NSLog(@"Failed to open Realm on background worker: %@", error);
            return;
        }

        NSTableView *tableView = weakSelf.chatsTableView;

        // Initial run of the query will pass nil for the change information
        if (! changes) {
            [tableView reloadData];
            return;
        }

        [tableView beginUpdates];
        [tableView removeRowsAtIndexes:[changes deletionsSet] withAnimation:NSTableViewAnimationSlideLeft];
        [tableView insertRowsAtIndexes:[changes insertionsSet] withAnimation:NSTableViewAnimationSlideRight];
        [tableView reloadDataForRowIndexes:[changes modificationsSet] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        [tableView endUpdates];
    }];
}

#pragma mark - Actions

- (IBAction)deleteChatButtonPressed:(NSButton *)sender
{
    NSInteger selectedRow = self.chatsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    OCTChat *chat = self.allChats[selectedRow];

    [self.manager.chats removeChatWithAllMessages:chat];
}

- (IBAction)callUserButtonPressed:(NSButton *)sender
{
    NSInteger selectedRow = self.chatsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    OCTChat *chat = self.allChats[selectedRow];

    [self.manager.calls callToChat:chat enableAudio:YES enableVideo:YES error:nil];
}

- (IBAction)sendFileButtonPressed:(id)sender
{
    NSInteger selectedRow = self.chatsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    OCTChat *chat = self.allChats[selectedRow];

    NSOpenPanel *panel = [NSOpenPanel openPanel];

    [panel runModal];

    NSString *path = [panel.URL path];

    [self.manager.files sendFile:path overrideFileName:nil toChat:chat failureBlock:nil];
}

#pragma mark - NSTextFieldDelegate

- (IBAction)chatTextFieldEntered:(NSTextField *)sender
{
    NSInteger selectedRow = self.chatsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    OCTChat *chat = self.allChats[selectedRow];

    [self.manager.chats sendMessageToChat:chat
                                     text:sender.stringValue
                                     type:OCTToxMessageTypeNormal
                                    error:nil];
    sender.stringValue = @"";
}

#pragma mark - NSTableViewDelegate

- (NSView *) tableView:(NSTableView *)tableView
    viewForTableColumn:(NSTableColumn *)tableColumn
                   row:(NSInteger)row
{
    NSTextField *field = [tableView
                          makeViewWithIdentifier:kCellIdent
                                           owner:self];

    if (! field) {
        field = [NSTextField new];
        field.identifier = kCellIdent;
    }

    field.selectable = YES;
    field.editable = NO;


    if (tableView == self.chatsTableView) {
        OCTChat *chat = self.allChats[row];
        OCTFriend *friend = [chat.friends firstObject];

        field.stringValue = (friend.isConnected) ? ([NSString stringWithFormat:@"%@ : Online", friend.nickname]) : friend.nickname;

    }
    else {
        OCTMessageAbstract *messageAbstract = self.conversationMessages[row];
        if (messageAbstract.messageText) {
            if ([messageAbstract isOutgoing]) {
                field.stringValue = [NSString stringWithFormat:@"%@: %@", self.manager.user.userName, messageAbstract.messageText.text];
            }
            else {
                OCTFriend *friend = [self.manager.objects objectWithUniqueIdentifier:messageAbstract.senderUniqueIdentifier
                                                                             forType:OCTFetchRequestTypeFriend];

                field.stringValue = [NSString stringWithFormat:@"%@: %@", friend.nickname, messageAbstract.messageText.text];
            }
        }
    }

    return field;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (notification.object != self.chatsTableView) {
        return;
    }

    NSInteger selectedRow = self.chatsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    OCTChat *chat = self.allChats[selectedRow];

    [self updateConversationControllerForChat:chat];

    [self.conversationTableView reloadData];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 50.0;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.chatsTableView) {
        return self.allChats.count;
    }
    else {
        return self.conversationMessages.count;
    }

    return 0;
}

#pragma mark - Private

- (void)updateConversationControllerForChat:(OCTChat *)chat
{
    [self.conversationMessagesNotificationToken stop];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chatUniqueIdentifier == %@", chat.uniqueIdentifier];
    self.conversationMessages = [self.manager.objects objectsForType:OCTFetchRequestTypeMessageAbstract predicate:predicate];

    __weak typeof(self) weakSelf = self;

    self.conversationMessagesNotificationToken = [self.conversationMessages addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *error) {
        if (error) {
            NSLog(@"Failed to open Realm on background worker: %@", error);
            return;
        }

        NSTableView *tableView = weakSelf.conversationTableView;

        // Initial run of the query will pass nil for the change information
        if (! changes) {
            [tableView reloadData];
            return;
        }

        [tableView beginUpdates];
        [tableView removeRowsAtIndexes:[changes deletionsSet] withAnimation:NSTableViewAnimationSlideLeft];
        [tableView insertRowsAtIndexes:[changes insertionsSet] withAnimation:NSTableViewAnimationSlideRight];
        [tableView reloadDataForRowIndexes:[changes modificationsSet] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        [tableView endUpdates];
    }];
}

@end
