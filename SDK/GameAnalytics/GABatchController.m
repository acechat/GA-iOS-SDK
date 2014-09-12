//
//  GABatchController.m
//  GameAnalytics
//
//  Created by Rick Chapman on 11/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "GABatchController.h"
#import "GALogger.h"

#import "GAReachability.h"

#import "GACoreDataController.h"
#import "GACoreDataHelper.h"
#import "NSManagedObjectContext+Save.h"

#import "GASender.h"

#import "GAEvents+Queries.h"
#import "GABusiness+Queries.h"
#import "GADesign+Queries.h"
#import "GAUser+Queries.h"
#import "GAError+Queries.h"

#import "NSObject+MD5.h"

#define API_VERSION @"1"


@interface GABatchController ()

@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, strong) NSString *gameKey;
@property (nonatomic, strong) NSString *secretKey;

@property (nonatomic, strong) GAReachability *hostReachability;
@property (nonatomic, strong) NSTimer *batchTimer;

@property (nonatomic, strong) NSDate *sessionTimeoutStarted;
@property (nonatomic, assign) BOOL sessionDidTimeOut;

@end

@implementation GABatchController

+ (GABatchController *)sharedInstance {
    static GABatchController *_sharedInstanceBC = nil;
    static dispatch_once_t oncePredicateBC;
    dispatch_once(&oncePredicateBC, ^{
        _sharedInstanceBC = [[self alloc] init];
        [_sharedInstanceBC initialiseDB];
    });
    return _sharedInstanceBC;
}

- (id)init {
    self = [super init];
    if (self) {
        [GALogger d:@"GABatchController Init"];
        
        _initialized = false;
        _sendEventInterval = 20;
        _sessionTimeoutDuration = 20;
        _sessionTimeoutStarted = nil;
        _sessionDidTimeOut = FALSE;
        _networkTimeoutDuration = 30;
        
        _autoBatch = TRUE;
        _batchTimer = nil;
        
        _localCaching = TRUE;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initialiseDB {
    
    //
    // If there are any events in the database with status GAStatusTypeSending when a GABatchController
    // is initialised, the previous run of the application must have crashed. These will block any more
    // uploads so we must reset their status to GAStatusTypeNew and they will upload again
    //

    [GALogger d:@"GABatchController initialiseDB"];

    // Grab a context
    NSManagedObjectContext *bgContext = [[GACoreDataController sharedInstance] backgroundContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = %d", GAStatusTypeSending];
    
    NSArray *results = [GACoreDataHelper searchObjectsInContext:bgContext
                                                     entityName:@"GAEvents"
                                                      predicate:predicate
                                                        sortKey:@"eventIdx"
                                                  sortAscending:TRUE];
    
    if ([results count]) {
        [GALogger d:@"%lu event(s) found of status 'Sending' to be reset to 'New' - previous crash implied", (unsigned long)[results count]];

        for (GAEvents *event in results) {
            event.status = GAStatusTypeNew;
        }
        [bgContext _GA_saveContextSilent];
    }

}

- (void)run {

    [GALogger d:@"GABatchController run"];

    //
    // Observe the k_GA_ReachabilityChangedNotification.
    //
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:k_GA_ReachabilityChangedNotification
                                               object:nil];
    
    self.hostReachability = [GAReachability reachabilityWithHostName:[self getHostName]];
    [self.hostReachability startNotifier];
    
    //
    // Set up state change observers
    //
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nowInForeground:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headingToForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(headingToBackground:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nowInBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    //
    // Start up the timer loop
    //
    
    [self startTimer];
}

- (void)startTimer {
    
    if (!self.autoBatch) {
        [GALogger d:@"GABatchController startTimer - aborted - autoBatch off"];
        return;
    }
    
    if (![self serverIsReachable]) {
        // Not connected - don't start timer
        [GALogger d:@"GABatchController startTimer - aborted - no network connection"];
        return;
    }

    if (nil != self.batchTimer) {
        // Must already have a running timer
        [GALogger d:@"GABatchController startTimer - aborted - timer already running"];
        return;
    }
    
    self.batchTimer = [NSTimer scheduledTimerWithTimeInterval:self.sendEventInterval
                                                       target:self
                                                     selector:@selector(batchTimerTick:)
                                                     userInfo:nil
                                                      repeats:YES];
    [GALogger i:@"Batch timer started"];
}

- (void)stopTimer {
    
    [self.batchTimer invalidate];
    self.batchTimer = nil;
    [GALogger i:@"Batch timer stopped"];
    
    if (![self serverIsReachable] && !self.localCaching) {
        [GABatchController deleteAllEvents];
    }
}

- (void)setSendEventInterval:(NSTimeInterval)sendEventInterval {
    _sendEventInterval = sendEventInterval;
    [GALogger d:@"Batch timer interval changed: %.2lf", sendEventInterval];
    
    if (self.batchTimer) {
        // Need to change a running timer
        [self stopTimer];
        [self startTimer];
    }
}

- (void)setAutoBatch:(BOOL)autoBatch {
    _autoBatch = autoBatch;

    // We may need to start or stop a timer on value change
    
    if (autoBatch) {
        [self startTimer];
    } else {
        [self stopTimer];
    }
}

- (void)sendManualBatch {
    if ([self serverIsReachable]) {
        [self batchTimerTick:nil];
    }
}

/**
 * Main routine called upon a timer tick. Does a db count for information only followed by checking for 
 * any events that are due for deletion.
 *
 * If there are any events in the process of being uploaded, this means another network call is ongoing.
 * In that case, this routine returns rather than start a new send.
 *
 * If we are still here, a fetch is done for any events to upload, of any type. They are filtered by the
 * GameKey and SecretKey of the first event so that all to be sent match. They are marked as Sending to
 * prevent any other operation occuring on them and then sent to the server.
 *
 */
- (void)batchTimerTick:(NSTimer *)timer {
    
    [GALogger d:@"Batch timer tick: %@", [NSDate date]];
    
    [self countAllEvents];
    [self checkForEventsToDelete];
    
    // Grab a context
    NSManagedObjectContext *bgContext = [[GACoreDataController sharedInstance] backgroundContext];
    
    //
    // Check for any events in the database of status -> Sending
    //
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = %d", GAStatusTypeSending];
    
    NSArray *results = [GACoreDataHelper searchObjectsInContext:bgContext
                                                     entityName:@"GAEvents"
                                                      predicate:predicate
                                                        sortKey:@"eventIdx"
                                                  sortAscending:TRUE];
    
    [GALogger d:@"%lu event(s) already uploading", (unsigned long)[results count]];

    if ([results count]) {
        [GALogger i:@"Cannot send more events at present - another send is ongoing"];
        return;
    }
    
    //
    // Find any events to be uploaded
    //
    
    predicate = [NSPredicate predicateWithFormat:@"status = %d", GAStatusTypeNew];
    
    results = [GACoreDataHelper searchObjectsInContext:bgContext
                                            entityName:@"GAEvents"
                                             predicate:predicate
                                               sortKey:@"eventIdx"
                                         sortAscending:TRUE];
    
    [GALogger d:@"%lu event(s) to upload", (unsigned long)[results count]];
    
    if ([results count]) {
        
        //
        // Need to filter by same gamekey
        //
        
        GAEvents *event = [results firstObject];
        NSString *gameKey = event.gameKey;
        NSString *secretKey = event.secretKey;
        
        predicate = [NSPredicate predicateWithFormat:@"gameKey = %@", gameKey];
        results = [results filteredArrayUsingPredicate:predicate];
        
        predicate = [NSPredicate predicateWithFormat:@"secretKey = %@", secretKey];
        results = [results filteredArrayUsingPredicate:predicate];

        [GALogger d:@"%lu of same gameKey and secretKey", (unsigned long)[results count]];
        
        //
        // Now upload them
        //
        
        [self sendAllEvents:results];
    }
    
}

- (NSInteger)countAllEvents {
    
    // Grab a context
    NSManagedObjectContext *bgContext = [[GACoreDataController sharedInstance] backgroundContext];
    
    NSArray *results = [GACoreDataHelper searchObjectsInContext:bgContext
                                                   entityName:@"GAEvents"
                                                    predicate:nil
                                                      sortKey:nil
                                                sortAscending:TRUE];
    
    [GALogger d:@"%lu events in database", (unsigned long)[results count]];
    return (NSInteger)[results count];
}

+ (void)deleteAllEvents {
    
    [GALogger d:@"deleteAllEvents"];

    // Grab a context
    NSManagedObjectContext *bgContext = [[GACoreDataController sharedInstance] backgroundContext];
    
    NSArray *results = [GACoreDataHelper searchObjectsInContext:bgContext
                                                   entityName:@"GAEvents"
                                                    predicate:nil
                                                      sortKey:nil
                                                sortAscending:TRUE];
    
    [GALogger i:@"%lu events to force delete", (unsigned long)[results count]];
    
    if ([results count]) {
        for (GAEvents *event in results) {
            [bgContext deleteObject:event];
        }
        
        [bgContext _GA_saveContextSilent];
    }
}


- (void)checkForEventsToDelete {
    
    // Grab a context
    NSManagedObjectContext *bgContext = [[GACoreDataController sharedInstance] backgroundContext];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status = %d", GAStatusTypeReadyToDelete];
    
    NSArray *results = [GACoreDataHelper searchObjectsInContext:bgContext
                                                   entityName:@"GAEvents"
                                                    predicate:predicate
                                                      sortKey:nil
                                                sortAscending:TRUE];
    
    [GALogger d:@"%lu events to delete", (unsigned long)[results count]];
    
    if ([results count]) {
        for (GAEvents *event in results) {
            [bgContext deleteObject:event];
        }
        
        [bgContext _GA_saveContextSilent];
    }
}

//
// Methods for sending data to API
//

// http://api.gameanalytics.com/API_VERSION/GAME_KEY/CATEGORY

- (NSString *)getHostName {
    return @"api.gameanalytics.com";
}

- (NSString *)getBaseUrl {
    return [NSString stringWithFormat:@"http://%@/%@", [self getHostName], API_VERSION];
}

- (void)sendAllEvents:(NSArray *)events {

    NSPredicate *predicate;
    NSArray *results;
    
    //
    // Check for each type of event and send them in turn
    //
    
    for (NSInteger eventType = GAEventTypeUser; eventType <= GAEventTypeError; eventType++) {
        
        predicate = [NSPredicate predicateWithFormat:@"eventTypeID = %d", eventType];
        NSString *eventStr = [GAEvents eventStringForType:eventType];
        
        results = [events filteredArrayUsingPredicate:predicate];
        if ([results count]) {
            
            [GALogger i:@"Sending %lu %@ events", (unsigned long)[results count], eventStr];
            [self sendEvents:results];
            
        } else {
            
            [GALogger i:@"No %@ events to send", eventStr];
        }
    }
}


- (void)sendEvents:(NSArray *)events {
    
    //
    // Build the url based on the type of the first event
    //
    
    NSString *theURL = [self getBaseUrl];
    
    GAEvents *event = [events firstObject];
    theURL = [theURL stringByAppendingFormat:@"/%@/", event.gameKey];
    
    NSString *eventStr = [GAEvents eventStringForType:[event.eventTypeID integerValue]];
    theURL = [theURL stringByAppendingString:eventStr];
    
    [GALogger d:theURL];

    //
    // Double check the sort order
    //
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"eventIdx" ascending:TRUE];
    NSArray *sortedEvents = [events sortedArrayUsingDescriptors:@[sortDescriptor] ];
    
    //
    // Build an array of events to convert to JSON
    //
    
    NSMutableArray *jsonArray = [NSMutableArray arrayWithCapacity:[sortedEvents count]];
    
    for (GAEvents *event in sortedEvents) {
    
        NSDictionary *eventDict = nil;

        if ([event.eventTypeID integerValue] == GAEventTypeBusiness) {
            GABusiness *specificEvent = (GABusiness *)event;
            eventDict = [specificEvent getDictionary];
        }
        
        if ([event.eventTypeID integerValue] == GAEventTypeDesign) {
            GADesign *specificEvent = (GADesign *)event;
            eventDict = [specificEvent getDictionary];
        }
        
        if ([event.eventTypeID integerValue] == GAEventTypeError) {
            GAError *specificEvent = (GAError *)event;
            eventDict = [specificEvent getDictionary];
        }
        
        if ([event.eventTypeID integerValue] == GAEventTypeUser) {
            GAUser *specificEvent = (GAUser *)event;
            eventDict = [specificEvent getDictionary];
        }
        
        if (nil != eventDict) {
            //[GALogger d:@"Event to send: %@", [eventDict description]];
            [jsonArray addObject:eventDict];
        }
    }
    
    [GALogger d:@"Object for JSON formatting: %@", jsonArray];

    //
    // Produce nice JSON for debug logging only
    //
    
    NSError *error = nil;
    NSData *prettyDataToSend = [NSJSONSerialization dataWithJSONObject:jsonArray
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:&error];
    // TODO - Check the error
    
    NSString *resultAsString = [[NSString alloc] initWithData:prettyDataToSend encoding:NSUTF8StringEncoding];
    [GALogger d:@"JSON Output: %@", resultAsString];

    // Produce compact JSON for transmission

    NSData *dataToSend = [NSJSONSerialization dataWithJSONObject:jsonArray
                                                         options:kNilOptions
                                                           error:&error];
    // TODO - Check the error

    NSString *strToSend = [[NSString alloc] initWithData:dataToSend encoding:NSUTF8StringEncoding];
    [GALogger d:@"JSON Compact Output: %@", strToSend];

    //
    // Build the request
    //
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:theURL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSString *authHash = [[strToSend stringByAppendingString:event.secretKey] _GA_md5];
    [request setValue:authHash forHTTPHeaderField:@"Authorization"];

    [GALogger d:@"Authorization Header: %@", authHash];

    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[strToSend length]] forHTTPHeaderField:@"Content-length"];
    [request setHTTPBody:[strToSend dataUsingEncoding:NSUTF8StringEncoding]];
    [request setTimeoutInterval:self.networkTimeoutDuration];
    
    //
    // We are ready to send.
    // Also grab the objectIDs as we will cross a thread boundary
    //
    
    NSMutableArray *objectIDs = [NSMutableArray arrayWithCapacity:[sortedEvents count]];
    for (GAEvents *event in sortedEvents) {
        [objectIDs addObject:event.objectID];
    }
    
    //
    // Open a GASender object to handle the transfer
    //
    
    GASender *sender = [[GASender alloc] init];
    [sender startWithRequest:request forEventIDs:objectIDs];
    
}


#pragma mark -
#pragma mark reachability and network changes

- (void)nowInForeground:(NSNotification *)notification {
    [GALogger d:@"GABatchController State: nowInForeground"];

    [self startTimer];
    
    if (self.sessionTimeoutStarted) {
        // We have a running session, check for timeout.
        
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.sessionTimeoutStarted];
        if (elapsed > self.sessionTimeoutDuration) {
            self.sessionDidTimeOut = TRUE;
            [GALogger d:@"GABatchController Timeout: session timed out"];
        } else {
            self.sessionDidTimeOut = FALSE;
            [GALogger d:@"GABatchController Timeout: session resumed"];
        }
        
        self.sessionTimeoutStarted = nil;
    }

}

- (void)nowInBackground:(NSNotification *)notification {
    [GALogger d:@"GABatchController State: nowInBackground"];

    [self stopTimer];
    self.sessionTimeoutStarted = [NSDate date];
}

- (void)headingToBackground:(NSNotification *)notification {
    [GALogger d:@"GABatchController State: headingToBackground"];
}

- (void)headingToForeground:(NSNotification *)notification {
    [GALogger d:@"GABatchController State: headingToForeground"];
}

- (BOOL)serverIsReachable {
    _GANetworkStatus netStatus = [self.hostReachability currentReachabilityStatus];
    
    if (netStatus == _GAReachableViaWiFi || netStatus == _GAReachableViaWWAN) {
        return TRUE;
    }

    return FALSE;
}

/*
 * Called by GAReachability whenever status changes.
 */
- (void)reachabilityChanged:(NSNotification *)note {
    
    [GALogger d:@"Reachability Changed"];
    
    GAReachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[GAReachability class]]);
    //    [self updateInterfaceWithReachability:curReach];
    // Do something
    
    _GANetworkStatus netStatus = [curReach currentReachabilityStatus];
    BOOL connectionRequired = [curReach connectionRequired];
    NSString *statusString = @"";
    
    switch (netStatus) {
        case _GANotReachable:        {
            statusString = NSLocalizedString(@"Access Not Available", @"Text field text for access is not available");
            /*
             Minor interface detail- connectionRequired may return YES even when the host is unreachable. We cover that up here...
             */
            connectionRequired = NO;
            
            [self stopTimer];
            break;
        }
            
        case _GAReachableViaWWAN:        {
            statusString = NSLocalizedString(@"Reachable WWAN", @"");
            
            [self startTimer];
            break;
        }
        case _GAReachableViaWiFi:        {
            statusString= NSLocalizedString(@"Reachable WiFi", @"");
            
            [self startTimer];
            break;
        }
    }
    
    [GALogger d:statusString];
    
}

- (BOOL)hasSessionTimedOut {
    
    if (!self.sessionDidTimeOut) {
        [GALogger d:@"hasSessionTimedOut FALSE"];
        return FALSE;
    }
    
    self.sessionDidTimeOut = FALSE;

    [GALogger d:@"hasSessionTimedOut TRUE"];

    return TRUE;
}

@end
