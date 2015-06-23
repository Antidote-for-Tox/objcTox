//
//  OCTChatsViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 22/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTChatsViewController.h"
#import "OCTConversationViewController.h"
#import "RBQFetchedResultsController.h"
#import "OCTChat.h"

@interface OCTChatsViewController () <RBQFetchedResultsControllerDelegate>

@property (strong, nonatomic) RBQFetchedResultsController *resultsController;

@end

@implementation OCTChatsViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    RBQFetchRequest *fetchRequest = [self.manager fetchRequestForType:OCTFetchRequestTypeChat withPredicate:nil];

    _resultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                sectionNameKeyPath:nil
                                                                         cacheName:nil];
    _resultsController.delegate = self;
    [_resultsController performFetch];

    self.title = @"Chats";

    return self;
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    OCTChat *chat = [self.resultsController objectAtIndexPath:indexPath];

    OCTConversationViewController *cv = [[OCTConversationViewController alloc] initWithManager:self.manager chat:chat];
    [self.navigationController pushViewController:cv animated:YES];
}

#pragma mark -  UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.resultsController numberOfRowsForSectionIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTChat *chat = [self.resultsController objectAtIndexPath:indexPath];

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

@end
