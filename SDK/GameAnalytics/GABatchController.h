//
//  GABatchController.h
//  GameAnalytics
//
//  Created by Rick Chapman on 11/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GABatchController : NSObject

/**
 * The amount of time, in seconds, between each batch of events being sent.
 * The default is 20 seconds.
 *
 */
@property (nonatomic, assign) NSTimeInterval sendEventInterval;

/**
 * The amount of time, in seconds, for a session to timeout so that
 * a new one is started when the application is restarted.
 * The default is 20 seconds.
 *
 */
@property (nonatomic, assign) NSTimeInterval sessionTimeoutDuration;

@property (nonatomic, assign) BOOL autoBatch;

@property (nonatomic, assign) BOOL localCaching;

@property (nonatomic, assign) NSTimeInterval networkTimeoutDuration;

/* 
 * Returns a singleton instance. Should always be used for access to the class
 *
 */
+ (GABatchController *)sharedInstance;

/*
 * Main method to start the batch controller. Must be called first.
 *
 */
- (void)run;

/* 
 * Convenience method to clear the database of all entries. Does not need a batch controller to be running
 *
 */
+ (void)deleteAllEvents;

/*
 * Delete all events that are flagged as GAStatusTypeReadyToDelete
 *
 */
- (void)checkForEventsToDelete;

/*
 * Method returns a count of database entries
 *
 * @returns integer
 */
- (NSInteger)countAllEvents;

/**
 * Determine if a session has timed out and a new SessionID should be generated. Note that this will reset
 * the internal status once read.
 *
 */
- (BOOL)hasSessionTimedOut;

- (void)sendManualBatch;

- (BOOL)serverIsReachable;

@end
