//
//  AppDelegate.m
//  GADemo
//
//  Created by Rick Chapman on 10/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "AppDelegate.h"
#import "GameAnalytics.h"
#import "GALogger.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }

    [GameAnalytics setDebugLogLevelVerbose:TRUE];
    [GameAnalytics enableExceptionHandler:TRUE];
    [GALogger setDebugLogging:TRUE];
    
    [GameAnalytics initializeWithGameKey:@"a12ad7e0a9fd7e2421dd7812f7f82370" secretKey:@"d3a8c48ac4a9fb90f36dc61a565f3dec4fdbadc8"];
    [GameAnalytics setSendEventsInterval:10];
    
    
    [GameAnalytics setUserID:@"ADADED35-45DB-4751-AD38-02E35D5E0B19"];
    
    //[GameAnalytics setMaximumEventStorage:6];
            
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
