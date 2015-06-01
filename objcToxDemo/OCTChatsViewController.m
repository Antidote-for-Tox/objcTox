//
//  OCTChatsViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 22/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTChatsViewController.h"
#import "OCTConversationViewController.h"

@interface OCTChatsViewController () <OCTArrayDelegate>

@property (strong, nonatomic) OCTArray *allChats;

@end

@implementation OCTChatsViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    _allChats = self.manager.chats.allChats;
    _allChats.delegate = self;

    self.title = @"Chats";

    return self;
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    OCTChat *chat = [self.allChats objectAtIndex:indexPath.row];

    OCTConversationViewController *cv = [[OCTConversationViewController alloc] initWithManager:self.manager chat:chat];
    [self.navigationController pushViewController:cv animated:YES];
}

#pragma mark -  UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.allChats.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTChat *chat = [self.allChats objectAtIndex:indexPath.row];

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

#pragma mark -  OCTArrayDelegate

- (void)OCTArrayWasUpdated:(OCTArray *)array
{
    [self.tableView reloadData];
}

@end
