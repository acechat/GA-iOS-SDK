//
//  GALogger.h
//  GameAnalytics
//
//  Created by Rick Chapman on 11/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum GALoggerMessageType : NSInteger {
    GALoggerMessageTypeError     = 0,
    GALoggerMessageTypeWarning   = 1,
    GALoggerMessageTypeInfo      = 2,
    GALoggerMessageTypeDebug     = 3,
} GALoggerMessageType;

extern NSString *k_GA_LoggerMessageNotification;

@interface GALogger : NSObject

+ (GALogger *)sharedInstance;

/*
 * Enables the logging of Info (i) level messages
 */
+ (void)setVerbose:(BOOL)verbose;

/*
 * Enables the logging of Debug (d) level messages
 */
+ (void)setDebugLogging:(BOOL)debug;

+ (void)i:(NSString *)format, ... ;
+ (void)w:(NSString *)format, ... ;
+ (void)e:(NSString *)format, ... ;
+ (void)d:(NSString *)format, ... ;


@end
