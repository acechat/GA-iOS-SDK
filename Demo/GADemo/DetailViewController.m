//
//  DetailViewController.m
//  GADemo
//
//  Created by Rick Chapman on 10/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "DetailViewController.h"
#import "GameAnalytics.h"

@interface DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) NSTimer *fpsTimer;
- (void)configureView;
@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        self.detailDescriptionLabel.text = [self.detailItem description];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loggerNotification:) name:k_GA_LoggerMessageNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loggerNotification:(NSNotification *)notification {
    //NSLog(@"Log: %@", notification.userInfo[@"message"]);
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (IBAction)purchaseCoins:(id)sender {
    [GameAnalytics newBusinessEventWithId:@"PurchaseCoins" currency:@"USD" amount:@999];
}

- (IBAction)switchGameKey:(id)sender {
    UISegmentedControl *control = (UISegmentedControl *)sender;
    if (control.selectedSegmentIndex == 0) {
        [GameAnalytics initializeWithGameKey:@"a12ad7e0a9fd7e2421dd7812f7f82370" secretKey:@"d3a8c48ac4a9fb90f36dc61a565f3dec4fdbadc8"];
    } else {
        [GameAnalytics initializeWithGameKey:@"713e0a87f12d697779c8cc0edb59774c" secretKey:@"1b308e23f545acba32bd5c5fada672cce0e388d0"];
    }
}

- (IBAction)clearDB:(id)sender {
    [GameAnalytics clearDatabase];
}

- (IBAction)sendManualBatch:(id)sender {
    [GameAnalytics manualBatch];
}

- (IBAction)setAutoBatch:(id)sender {
    UISwitch *control = (UISwitch *)sender;
    BOOL value = control.on;
    
    [GameAnalytics setAutoBatch:value];
}

- (IBAction)setDBLimit:(id)sender {
    UISwitch *control = (UISwitch *)sender;
    BOOL value = control.on;

    if (value) {
        [GameAnalytics setMaximumEventStorage:6];
    } else {
        [GameAnalytics setMaximumEventStorage:0];
    }
}

- (IBAction)causeCrash:(id)sender {
    NSException *exception = [NSException exceptionWithName:@"GA Test Crash" reason:@"Wrong button was pressed that caused this test crash" userInfo:nil];
    [exception raise];
}

- (IBAction)startFPS:(id)sender {
    
    NSTimeInterval timeTick = 1 / [self.fpsText.text doubleValue];
    NSLog(@"timeTick: %lf", timeTick);
    
    self.fpsTimer = [NSTimer scheduledTimerWithTimeInterval:timeTick
                                                       target:self
                                                     selector:@selector(fpsTimerTick:)
                                                     userInfo:nil
                                                      repeats:YES];

}

- (void)fpsTimerTick:(NSTimer *)timer {
    [GameAnalytics logFPS];
}

- (IBAction)stopFPS:(id)sender {
    
    [self.fpsTimer invalidate];
    self.fpsTimer = nil;
    
    [GameAnalytics stopLoggingFPS];
}

- (IBAction)updateSession:(id)sender {
    [GameAnalytics updateSessionID];
}

- (IBAction)doDesignEvent:(id)sender {
    [GameAnalytics newDesignEventWithId:@"PickAmmo:Bullets" value:@25];
}

- (IBAction)doErrorEvent:(id)sender {
    [GameAnalytics newErrorEventWithMessage:@"Game Stalled" severity:GASeverityTypeError];
    [GameAnalytics newErrorEventWithMessage:@"IndexOutOfRangeException: Array index is out of range. Shape.Update ()" severity:GASeverityTypeCritical area:@"Level 1" x:@136.2 y:@210.9 z:@-16.3];
}

- (IBAction)doUserEvent:(id)sender {
    [GameAnalytics setUserInfoWithGender:@"M" birthYear:@1977 friendCount:@7];
    [GameAnalytics setReferralInfoWithPublisher:@"ChartBoost" installSite:@"Facebook" installCampaign:@"Launch" installAdgroup:nil installAd:@"Launch Ad 1" installKeyword:nil];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
