// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import "OCTManager.h"

@interface OCTTableViewController : UIViewController

@property (strong, nonatomic, readonly) UITableView *tableView;
@property (strong, nonatomic, readonly) id<OCTManager> manager;

- (instancetype)initWithManager:(id<OCTManager>)manager;

- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath;

- (void)showActionSheet:(void (^)(UIActionSheet *sheet))block;
- (void)addToSheet:(UIActionSheet *)sheet copyButtonWithValue:(id)value;
- (void)addToSheet:(UIActionSheet *)sheet textEditButtonWithValue:(id)value block:(void (^)(NSString *string))block;
- (void)            addToSheet:(UIActionSheet *)sheet
    multiEditButtonWithOptions:(NSArray *)options
                         block:(void (^)(NSUInteger index))block;

// Value can be NSString or NSNumber
- (NSString *)stringFromValue:(id)value;
- (NSString *)stringFromUserStatus:(OCTToxUserStatus)status;
- (NSString *)stringFromConnectionStatus:(OCTToxConnectionStatus)status;

// Shows error if it isn't nil.
- (void)maybeShowError:(NSError *)error;

@end
