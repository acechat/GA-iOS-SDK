//
//  GALogger.m
//  GameAnalytics
//
//  Created by Rick Chapman on 11/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "GALogger.h"

@interface GALogger ()
@property (nonatomic, assign) BOOL verbose;
@property (nonatomic, assign) BOOL fullDebugLogging;
@property (nonatomic, strong) NSString *tag;
@end

NSString *k_GA_LoggerMessageNotification = @"k_GA_LoggerMessageNotification";

@implementation GALogger

+ (GALogger *)sharedInstance {
    static GALogger *_sharedInstanceLg = nil;
    static dispatch_once_t oncePredicateLg;
    dispatch_once(&oncePredicateLg, ^{
        _sharedInstanceLg = [[self alloc] init];
    });
    return _sharedInstanceLg;
}

- (id)init {
    self = [super init];
    if (self) {
        self.verbose = FALSE;
        self.fullDebugLogging = FALSE;
        self.tag = @"GameAnalytics";
    }
    return self;
}

+ (void)setVerbose:(BOOL)verbose {
    [[GALogger sharedInstance] setVerbose:verbose];
}

+ (void)setDebugLogging:(BOOL)debug {
    [[GALogger sharedInstance] setFullDebugLogging:debug];
}

+ (void)i:(NSString *)format, ... {
    va_list args, args_copy;
    va_start(args, format);
    va_copy(args_copy, args);
    va_end(args);
    
    GALogger *ga =[GALogger sharedInstance];
    if (!ga.verbose) {
        // No logging of info unless in verbose mode
        return;
    }

    NSString *logString = [[NSString alloc] initWithFormat:format
                                                 arguments:args_copy];
    
    NSString *message = [NSString stringWithFormat:@"I/%@: %@", ga.tag, logString];
    NSLog(@"%@", message);
    [ga sendNotificationMessage:message ofType:GALoggerMessageTypeInfo];

    va_end(args_copy);
}

+ (void)w:(NSString *)format, ... {
    va_list args, args_copy;
    va_start(args, format);
    va_copy(args_copy, args);
    va_end(args);
    
    NSString *logString = [[NSString alloc] initWithFormat:format
                                                 arguments:args_copy];
    
    GALogger *ga =[GALogger sharedInstance];
    NSString *message = [NSString stringWithFormat:@"W/%@: %@", ga.tag, logString];
    NSLog(@"%@", message);
    [ga sendNotificationMessage:message ofType:GALoggerMessageTypeWarning];

    va_end(args_copy);
}

+ (void)e:(NSString *)format, ... {
    va_list args, args_copy;
    va_start(args, format);
    va_copy(args_copy, args);
    va_end(args);
    
    NSString *logString = [[NSString alloc] initWithFormat:format
                                                 arguments:args_copy];
    
    GALogger *ga =[GALogger sharedInstance];
    NSString *message = [NSString stringWithFormat:@"E/%@: %@", ga.tag, logString];
    NSLog(@"%@", message);
    [ga sendNotificationMessage:message ofType:GALoggerMessageTypeError];

    va_end(args_copy);
}

+ (void)d:(NSString *)format, ... {
    va_list args, args_copy;
    va_start(args, format);
    va_copy(args_copy, args);
    va_end(args);

    GALogger *ga =[GALogger sharedInstance];
    if (!ga.fullDebugLogging) {
        // No logging of debug info unless in full debug logging mode
        return;
    }

    NSString *logString = [[NSString alloc] initWithFormat:format
                                                 arguments:args_copy];
    
    NSString *message = [NSString stringWithFormat:@"D/%@: %@", ga.tag, logString];
    NSLog(@"%@", message);
    [ga sendNotificationMessage:message ofType:GALoggerMessageTypeDebug];
    
    va_end(args_copy);
}

- (void)sendNotificationMessage:(NSString *)message ofType:(GALoggerMessageType)type {
        [[NSNotificationCenter defaultCenter] postNotificationName:k_GA_LoggerMessageNotification
                                                            object:nil
                                                          userInfo:@{@"type": @(type), @"message": message}
         ];
}

@end
