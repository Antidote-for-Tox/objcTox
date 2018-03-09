// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "OCTChatsViewController.h"
#import "OCTConversationViewController.h"
#import "OCTChat.h"
#import "OCTSubmanagerObjects.h"

@interface OCTChatsViewController ()

@property (strong, nonatomic) RLMResults<OCTChat *> *chats;
@property (strong, nonatomic) RLMNotificationToken *chatsNotificationToken;

@end

@implementation OCTChatsViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(id<OCTManager>)manager
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    _chats = [self.manager.objects objectsForType:OCTFetchRequestTypeChat predicate:nil];
    self.title = @"Chats";

    return self;
}

- (void)dealloc
{
    [self.chatsNotificationToken invalidate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak typeof(self) weakSelf = self;

    self.chatsNotificationToken = [self.chats addNotificationBlock:^(RLMResults *results, RLMCollectionChange *changes, NSError *error) {
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    OCTChat *chat = self.chats[indexPath.row];

    OCTConversationViewController *cv = [[OCTConversationViewController alloc] initWithManager:self.manager chat:chat];
    [self.navigationController pushViewController:cv animated:YES];
}

#pragma mark -  UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.chats.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTChat *chat = self.chats[indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@"Chat\n"
                           @"uniqueIdentifier %@\n"
                           @"friends %@\n"
                           @"enteredText %@\n"
                           @"lastReadDate %@\n"
                           @"hasUnreadMessages %d\n"
                           @"lastMessage: %@",
                           chat.uniqueIdentifier, chat.friends, chat.enteredText, chat.lastReadDate, [chat hasUnreadMessages], chat.lastMessage];

    return cell;
}

@end
