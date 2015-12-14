//
//  OCTFriendsViewController.m
//  objcTox
//
//  Created by Chuong Vu on 12/12/15.
//  Copyright © 2015 dvor. All rights reserved.
//

#import "OCTFriendsViewController.h"
#import "RBQFetchedResultsController.h"
#import "OCTFriend.h"
#import "OCTFriendRequest.h"
#import "OCTSubmanagerObjects.h"
#import "OCTSubmanagerFriends.h"

static NSString *const kNibName = @"OCTFriendsViewController";
static NSString *const kCellIdent = @"cellIdent";

@interface OCTFriendsViewController () <NSTableViewDataSource,
                                        NSTableViewDelegate,
                                        RBQFetchedResultsControllerDelegate>

@property (strong, nonatomic) OCTManager *manager;
@property (strong, nonatomic) RBQFetchedResultsController *friendResultsController;
@property (strong, nonatomic) RBQFetchedResultsController *friendRequestResultsController;

@property (weak) IBOutlet NSButton *acceptButton;
@property (weak) IBOutlet NSButton *rejectButton;
@property (unsafe_unretained) IBOutlet NSTextView *friendInfoTextField;

@property (weak) IBOutlet NSTableView *friendsTableView;
@property (weak) IBOutlet NSTableView *requestsTableView;

@end

@implementation OCTFriendsViewController

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super initWithNibName:kNibName bundle:nil];

    if (! self) {
        return nil;
    }

    _manager = manager;

    RBQFetchRequest *fetchRequest = [self.manager.objects
                                     fetchRequestForType:OCTFetchRequestTypeFriend
                                     withPredicate:nil];

    _friendResultsController = [[RBQFetchedResultsController alloc]
                                initWithFetchRequest:fetchRequest
                                sectionNameKeyPath:nil
                                cacheName:nil];
    _friendResultsController.delegate = self;
    [_friendResultsController performFetch];

    fetchRequest = [self.manager.objects
                    fetchRequestForType:OCTFetchRequestTypeFriendRequest
                    withPredicate:nil];

    _friendRequestResultsController = [[RBQFetchedResultsController alloc]
                                initWithFetchRequest:fetchRequest
                                sectionNameKeyPath:nil
                                cacheName:nil];
    _friendRequestResultsController.delegate = self;
    [_friendRequestResultsController performFetch];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupRejectAcceptButtons];
}

- (void)setupRejectAcceptButtons
{
    self.acceptButton.target = self;
    self.acceptButton.action = @selector(acceptFriendRequests);
    self.rejectButton.target = self;
    self.rejectButton.action = @selector(rejectFriendRequests);
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{

    if (tableView == self.friendsTableView) {
        return [self.friendResultsController numberOfRowsForSectionIndex:0];
    }

    return [self.friendRequestResultsController numberOfRowsForSectionIndex:0];

}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView
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

    if (tableView == self.friendsTableView) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
        OCTFriend *friend = [self.friendResultsController objectAtIndexPath:path];

        NSString *titleString = (friend.isConnected) ? [NSString stringWithFormat:@"%@ : Online", friend.nickname] : friend.nickname;

        field.stringValue = titleString;

        return field;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    OCTFriendRequest *request = [self.friendRequestResultsController objectAtIndexPath:path];
    field.stringValue = request.publicKey;

    return field;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (notification.object == self.friendsTableView) {
        NSInteger selectedRow = self.friendsTableView.selectedRow;
        NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];
        OCTFriend *friend = [self.friendResultsController objectAtIndexPath:path];

        self.friendInfoTextField.string = [NSString stringWithFormat:
                                            @"friendNumber %u\n"
                                            @"publicKey %@\n"
                                            @"name %@\n"
                                            @"nickname %@\n"
                                            @"statusMessage %@\n"
                                            @"status %@\n"
                                            @"isConnected %d\n"
                                            @"connectionStatus %@\n"
                                            @"lastSeenOnline %@\n"
                                            @"isTyping %d",
                                            friend.friendNumber,
                                            friend.publicKey,
                                            friend.name,
                                            friend.nickname,
                                            friend.statusMessage,
                                            [self stringFromUserStatus:friend.status],
                                            friend.isConnected,
                                            [self stringFromConnectionStatus:friend.connectionStatus],
                                            friend.lastSeenOnline,
                                            friend.isTyping];

    }
}

#pragma mark -  RBQFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller
{
    NSTableView *tableView = (controller == self.friendRequestResultsController) ? self.requestsTableView : self.friendsTableView;

    [tableView beginUpdates];
}

- (void) controller:(RBQFetchedResultsController *)controller
    didChangeObject:(RBQSafeRealmObject *)anObject
        atIndexPath:(NSIndexPath *)indexPath
      forChangeType:(RBQFetchedResultsChangeType)type
       newIndexPath:(NSIndexPath *)newIndexPath
{
    NSTableView *tableView = (controller == self.friendRequestResultsController) ? self.requestsTableView : self.friendsTableView;

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
    NSTableView *tableView = (controller == self.friendRequestResultsController) ? self.requestsTableView : self.friendsTableView;

    @try {
        [tableView endUpdates];
    }
    @catch (NSException *ex) {
        [controller reset];
        [tableView reloadData];
    }
}

#pragma mark - Actions

- (IBAction)addFriendReturn:(NSTextField *)sender
{
    [self.manager.friends
     sendFriendRequestToAddress:sender.stringValue
     message:@"Friend request from objcTox Mac OSX Demo"
     error:nil];
}

- (IBAction)removeFriendButtonPressed:(NSButton *)sender
{
    NSInteger selectedRow = self.friendsTableView.selectedRow;

    if (selectedRow == -1) {
        return;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    OCTFriend *friend = [self.friendResultsController objectAtIndexPath:path];

    [self.manager.friends removeFriend:friend error:nil];
}

#pragma mark - Private

- (void)acceptFriendRequests
{
    NSInteger selectedRow = self.requestsTableView.selectedRow;

    if (selectedRow == -1) {
        return;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    OCTFriendRequest *request = [self.friendRequestResultsController objectAtIndexPath:path];

    [self.manager.friends approveFriendRequest:request error:nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.requestsTableView reloadData];
    });
}

- (void)rejectFriendRequests
{
    NSInteger selectedRow = self.requestsTableView.selectedRow;

    if (selectedRow == -1) {
        return;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    OCTFriendRequest *request = [self.friendRequestResultsController objectAtIndexPath:path];

    [self.manager.friends removeFriendRequest:request];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.requestsTableView reloadData];
    });
}

- (NSString *)stringFromUserStatus:(OCTToxUserStatus)status
{
    switch (status) {
        case OCTToxUserStatusNone:
            return @"None";
        case OCTToxUserStatusAway:
            return @"Away";
        case OCTToxUserStatusBusy:
            return @"Busy";
    }
}

- (NSString *)stringFromConnectionStatus:(OCTToxConnectionStatus)status
{
    switch (status) {
        case OCTToxConnectionStatusNone:
            return @"None";
        case OCTToxConnectionStatusTCP:
            return @"TCP";
        case OCTToxConnectionStatusUDP:
            return @"UDP";
    }
}

@end
