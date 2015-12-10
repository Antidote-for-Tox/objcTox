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

static NSString *const kNibName = @"OCTFriendsViewController";
static NSString *const kFriendIdentifier = @"friendIdent";
static NSString *const kRequestIdentifier = @"RequestIdent";

@interface OCTFriendsViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (strong, nonatomic) OCTManager *manager;
@property (strong, nonatomic) RBQFetchedResultsController *friendResultsController;
@property (strong, nonatomic) RBQFetchedResultsController *friendRequestResultsController;

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

    [_friendRequestResultsController performFetch];

    fetchRequest = [self.manager.objects
                    fetchRequestForType:OCTFetchRequestTypeFriendRequest
                    withPredicate:nil];

    _friendRequestResultsController = [[RBQFetchedResultsController alloc]
                                initWithFetchRequest:fetchRequest
                                sectionNameKeyPath:nil
                                cacheName:nil];

    [_friendRequestResultsController performFetch];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

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
    if (tableView == self.friendsTableView) {
        NSTextField *field = [tableView makeViewWithIdentifier:kFriendIdentifier owner:self];

        if (! field) {
            field = [NSTextField new];
            field.identifier = kFriendIdentifier;
        }

        NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
        OCTFriend *friend = [self.friendResultsController objectAtIndexPath:path];

        field.stringValue = friend.name;
    }

    NSButton *button = [NSButton new];
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    OCTFriendRequest *request = [self.friendRequestResultsController objectAtIndexPath:path];
    button.title = request.publicKey;


    return button;
}

@end
