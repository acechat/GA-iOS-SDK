//
//  DetailViewController.h
//  GADemo
//
//  Created by Rick Chapman on 10/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;


- (IBAction)purchaseCoins:(id)sender;
- (IBAction)doDesignEvent:(id)sender;
- (IBAction)doErrorEvent:(id)sender;
- (IBAction)doUserEvent:(id)sender;

- (IBAction)switchGameKey:(id)sender;
- (IBAction)clearDB:(id)sender;

- (IBAction)sendManualBatch:(id)sender;
- (IBAction)setAutoBatch:(id)sender;
- (IBAction)setDBLimit:(id)sender;

- (IBAction)causeCrash:(id)sender;

- (IBAction)startFPS:(id)sender;
- (IBAction)stopFPS:(id)sender;

- (IBAction)updateSession:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *fpsText;


@end
