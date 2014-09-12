//
//  MasterViewController.h
//  GADemo
//
//  Created by Rick Chapman on 10/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
