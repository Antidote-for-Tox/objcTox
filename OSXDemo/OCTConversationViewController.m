//
//  OCTConversationViewController.m
//  objcTox
//
//  Created by Chuong Vu on 12/20/15.
//  Copyright © 2015 dvor. All rights reserved.
//

#import "OCTConversationViewController.h"
#import "RBQFetchedResultsController.h"
#import "OCTSubmanagerObjects.h"
#import "OCTSubmanagerChats.h"
#import "OCTFriend.h"
#import "OCTChat.h"
#import "OCTMessageAbstract.h"
#import "OCTSubmanagerUser.h"
#import "OCTSubmanagerCalls.h"
#import "OCTSubmanagerFiles.h"
#import "OCTMessageText.h"

static NSString *const kCellIdent = @"cellIdent";

@interface OCTConversationViewController () <NSTableViewDataSource,
                                             NSTableViewDelegate,
                                             RBQFetchedResultsControllerDelegate, NSTextFieldDelegate>

@property (weak) IBOutlet NSTableView *chatsViewController;
@property (weak, nonatomic) OCTManager *manager;
@property (strong, nonatomic) RBQFetchedResultsController *chatResultsController;
@property (strong, nonatomic) RBQFetchedResultsController *conversationResultsController;
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

    RBQFetchRequest *fetchRequest = [self.manager.objects
                                     fetchRequestForType:OCTFetchRequestTypeChat
                                           withPredicate:nil];

    _chatResultsController = [[RBQFetchedResultsController alloc]
                              initWithFetchRequest:fetchRequest
                                sectionNameKeyPath:nil cacheName:nil];

    _chatResultsController.delegate = self;
    [_chatResultsController performFetch];

    _conversationResultsController = [RBQFetchedResultsController new];
    _conversationResultsController.delegate = self;

    return self;
}

#pragma mark - Actions

- (IBAction)deleteChatButtonPressed:(NSButton *)sender
{
    NSInteger selectedRow = self.chatsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];

    OCTChat *chat = [self.chatResultsController objectAtIndexPath:path];

    [self.manager.chats removeChatWithAllMessages:chat];
}

- (IBAction)callUserButtonPressed:(NSButton *)sender
{
    NSInteger selectedRow = self.chatsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];

    OCTChat *chat = [self.chatResultsController objectAtIndexPath:path];

    [self.manager.calls callToChat:chat enableAudio:YES enableVideo:YES error:nil];
}

- (IBAction)sendFileButtonPressed:(id)sender
{
    NSInteger selectedRow = self.chatsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    OCTChat *chat = [self.chatResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:selectedRow inSection:0]];

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

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    OCTChat *chat = [self.chatResultsController objectAtIndexPath:path];

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


    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];

    if (tableView == self.chatsTableView) {

        OCTChat *chat = [self.chatResultsController objectAtIndexPath:path];
        OCTFriend *friend = [chat.friends firstObject];

        field.stringValue = (friend.isConnected) ? ([NSString stringWithFormat : @"%@ : Online", friend.nickname]) : friend.nickname;

    }
    else {
        OCTMessageAbstract *messageAbstract = [self.conversationResultsController objectAtIndexPath:path];
        if (messageAbstract.messageText) {
            if (messageAbstract.sender) {
                field.stringValue = [NSString stringWithFormat:@"%@: %@", messageAbstract.sender.nickname, messageAbstract.messageText.text];
            }
            else {
                field.stringValue = [NSString stringWithFormat:@"%@: %@", self.manager.user.userName, messageAbstract.messageText.text];
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

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    OCTChat *chat = [self.chatResultsController objectAtIndexPath:path];

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
        return [self.chatResultsController numberOfRowsForSectionIndex:0];
    }
    else {
        return [self.conversationResultsController numberOfRowsForSectionIndex:0];
    }

    return 0;
}

#pragma mark -  RBQFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller
{
    NSTableView *tableView = (self.chatResultsController == controller) ? self.chatsTableView : self.conversationTableView;
    [tableView beginUpdates];
}

- (void) controller:(RBQFetchedResultsController *)controller
    didChangeObject:(RBQSafeRealmObject *)anObject
        atIndexPath:(NSIndexPath *)indexPath
      forChangeType:(RBQFetchedResultsChangeType)type
       newIndexPath:(NSIndexPath *)newIndexPath
{
    NSTableView *tableView = (self.chatResultsController == controller) ? self.chatsTableView : self.conversationTableView;

    NSIndexSet *newSet = [[NSIndexSet alloc] initWithIndex:newIndexPath.row];
    NSIndexSet *oldSet = [[NSIndexSet alloc] initWithIndex:indexPath.row];
    NSIndexSet *columnSet = [[NSIndexSet alloc] initWithIndex:0];


    switch (type) {
        case RBQFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexes:newSet withAnimation:NSTableViewAnimationSlideRight];
            break;
        case RBQFetchedResultsChangeDelete:
            if (tableView == self.chatsViewController) {
                [tableView removeRowsAtIndexes:oldSet withAnimation:NSTableViewAnimationSlideLeft];
                [self selectFirstChat];
            }
            break;
        case RBQFetchedResultsChangeUpdate:
            [tableView reloadDataForRowIndexes:oldSet columnIndexes:columnSet];
            break;
        case RBQFetchedResultsChangeMove:
            [tableView removeRowsAtIndexes:oldSet withAnimation:NSTableViewAnimationSlideLeft];
            [tableView insertRowsAtIndexes:newSet withAnimation:NSTableViewAnimationSlideRight];
            break;
    }
}

- (void)controllerDidChangeContent:(RBQFetchedResultsController *)controller
{

    NSTableView *tableView = (self.chatResultsController == controller) ? self.chatsTableView : self.conversationTableView;

    @try {
        [tableView endUpdates];
    }
    @catch (NSException *ex) {
        [controller reset];
        [tableView reloadData];
    }
}

#pragma mark - Private

- (void)updateConversationControllerForChat:(OCTChat *)chat
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chat.uniqueIdentifier == %@", chat.uniqueIdentifier];
    RBQFetchRequest *fetchRequest = [self.manager.objects fetchRequestForType:OCTFetchRequestTypeMessageAbstract withPredicate:predicate];
    [self.conversationResultsController updateFetchRequest:fetchRequest
                                        sectionNameKeyPath:nil
                                            andPeformFetch:YES];
}

- (void)selectFirstChat
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
    OCTChat *chat = [self.chatResultsController objectAtIndexPath:path];

    if (chat) {
        NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:0];
        // workaround for deadlock in objcTox
        // https://github.com/Antidote-for-Tox/objcTox/issues/51
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.chatsTableView selectRowIndexes:indexSet byExtendingSelection:NO];
        });
    }
}
@end
