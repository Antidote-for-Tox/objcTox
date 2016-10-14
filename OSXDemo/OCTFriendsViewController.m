// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTFriendsViewController.h"
#import "OCTFriend.h"
#import "OCTFriendRequest.h"
#import "OCTSubmanagerObjects.h"
#import "OCTSubmanagerFriends.h"
#import "OCTSubmanagerChats.h"
#import "RLMCollectionChange+IndexSet.h"

static NSString *const kNibName = @"OCTFriendsViewController";
static NSString *const kCellIdent = @"cellIdent";

@interface OCTFriendsViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (weak, nonatomic) OCTManager *manager;

@property (strong, nonatomic) RLMResults<OCTFriend *> *friends;
@property (strong, nonatomic) RLMNotificationToken *friendsNotificationToken;
@property (strong, nonatomic) RLMResults<OCTFriendRequest *> *friendRequests;
@property (strong, nonatomic) RLMNotificationToken *friendRequestsNotificationToken;

@property (weak) IBOutlet NSButton *acceptButton;
@property (weak) IBOutlet NSButton *rejectButton;
@property (unsafe_unretained) IBOutlet NSTextView *friendInfoTextField;

@property (weak) IBOutlet NSTableView *friendsTableView;
@property (weak) IBOutlet NSTableView *requestsTableView;
@property (weak) IBOutlet NSImageView *avatarImageView;

@end

@implementation OCTFriendsViewController

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super initWithNibName:kNibName bundle:nil];

    if (! self) {
        return nil;
    }

    _manager = manager;

    _friends = [self.manager.objects objectsForType:OCTFetchRequestTypeFriend predicate:nil];
    _friendRequests = [self.manager.objects objectsForType:OCTFetchRequestTypeFriendRequest predicate:nil];

    return self;
}

- (void)dealloc
{
    [self.friendsNotificationToken stop];
    [self.friendRequestsNotificationToken stop];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;

    self.friendsNotificationToken = [self.friends addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *error) {
        [weakSelf realmWasUpdated:changes tableView:weakSelf.friendsTableView error:error];
    }];

    self.friendRequestsNotificationToken = [self.friendRequests addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *error) {
        [weakSelf realmWasUpdated:changes tableView:weakSelf.requestsTableView error:error];
    }];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{

    if (tableView == self.friendsTableView) {
        return self.friends.count;
    }
    else if (tableView == self.requestsTableView) {
        return self.friendRequests.count;
    }

    return 0;
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

    if (tableView == self.friendsTableView) {
        OCTFriend *friend = self.friends[row];
        field.stringValue = (friend.isConnected) ? ([NSString stringWithFormat:@"%@ : Online", friend.nickname]) : friend.nickname;

    }
    else if (tableView == self.requestsTableView) {
        OCTFriendRequest *request = self.friendRequests[row];
        field.stringValue = request.publicKey;
    }

    return field;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (notification.object == self.friendsTableView) {
        OCTFriend *friend = self.friends[self.friendsTableView.selectedRow];

        self.avatarImageView.image = [[NSImage alloc] initWithData:friend.avatarData];
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

    if (selectedRow < 0) {
        return;
    }

    OCTFriend *friend = self.friends[selectedRow];

    [self.manager.friends removeFriend:friend error:nil];
}

- (IBAction)createChatButtonPressed:(NSButton *)sender
{
    NSInteger selectedRow = self.friendsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    OCTFriend *friend = self.friends[selectedRow];

    [self.manager.chats getOrCreateChatWithFriend:friend];
}

- (IBAction)proceedWithFriendRequest:(NSButton *)sender
{
    NSInteger selectedRow = self.requestsTableView.selectedRow;

    if (selectedRow < 0) {
        return;
    }

    OCTFriendRequest *request = self.friendRequests[selectedRow];

    if (sender == self.acceptButton) {
        [self.manager.friends approveFriendRequest:request error:nil];
    }
    else {
        [self.manager.friends removeFriendRequest:request];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.requestsTableView reloadData];
    });
}

#pragma mark - Private

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

- (void)realmWasUpdated:(RLMCollectionChange *)changes tableView:(NSTableView *)tableView error:(NSError *)error
{
    if (error) {
        NSLog(@"Failed to open Realm on background worker: %@", error);
        return;
    }

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
}

@end
