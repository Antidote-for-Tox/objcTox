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

static NSString *const kCellIdent = @"cellIdent";

@interface OCTConversationViewController () <NSTableViewDataSource,
                                             NSTableViewDelegate,
                                             RBQFetchedResultsControllerDelegate>

@property (weak) IBOutlet NSTableView *chatsViewController;
@property (strong, nonatomic) OCTManager *manager;
@property (strong, nonatomic) RBQFetchedResultsController *chatResultsController;
@property (weak) IBOutlet NSTableView *chatsTableView;

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

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Actions

- (IBAction)deleteChatButtonPressed:(NSButton *)sender
{
    NSInteger selectedRow = self.chatsTableView.selectedRow;
    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];

    OCTChat *chat = [self.chatResultsController objectAtIndexPath:path];
    [self.manager.chats removeChatWithAllMessages:chat];
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

        field.stringValue = (friend.isConnected) ? [NSString stringWithFormat : @"%@ : Online", friend.nickname] : friend.nickname;

    }

    return field;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.chatsTableView) {
        return [self.chatResultsController numberOfRowsForSectionIndex:0];
    }
    return 0;
}

#pragma mark -  RBQFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller
{
    [self.chatsTableView beginUpdates];
}

- (void) controller:(RBQFetchedResultsController *)controller
    didChangeObject:(RBQSafeRealmObject *)anObject
        atIndexPath:(NSIndexPath *)indexPath
      forChangeType:(RBQFetchedResultsChangeType)type
       newIndexPath:(NSIndexPath *)newIndexPath
{
    NSTableView *tableView = self.chatsTableView;

    NSIndexSet *newSet = [[NSIndexSet alloc] initWithIndex:newIndexPath.row];
    NSIndexSet *oldSet = [[NSIndexSet alloc] initWithIndex:indexPath.row];
    NSIndexSet *columnSet = [[NSIndexSet alloc] initWithIndex:0];


    switch (type) {
        case RBQFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexes:newSet withAnimation:NSTableViewAnimationSlideRight];
            break;
        case RBQFetchedResultsChangeDelete:
            [tableView removeRowsAtIndexes:oldSet withAnimation:NSTableViewAnimationSlideLeft];
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

    NSTableView *tableView = self.chatsTableView;

    @try {
        [tableView endUpdates];
    }
    @catch (NSException *ex) {
        [controller reset];
        [tableView reloadData];
    }
}


@end
