//
//  OCTChatsViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 22/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTChatsViewController.h"

@interface OCTChatsViewController ()

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

    self.title = @"Chats";

    return self;
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        @"lastMessage %@\n"
        @"enteredText %@\n"
        @"lastReadDate %@\n"
        @"hasUnreadMessages %d",
        chat.uniqueIdentifier, chat.friends, chat.lastMessage, chat.enteredText, chat.lastReadDate, [chat hasUnreadMessages]];

    return cell;
}

@end
