//
//  NSManagedObjectContext+Save.m
//
//  Created by Rick Chapman on 18/05/2012.
//  Copyright (c) 2012 Parkview Consultants. All rights reserved.
//

#import "NSManagedObjectContext+Save.h"

@implementation NSManagedObjectContext (Save)

- (void)_GA_showErrors:(NSError *)error {
    NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if (detailedErrors != nil && [detailedErrors count] > 0) {
        for (NSError* detailedError in detailedErrors) {
            NSLog(@"  DetailedError: %@", [detailedError userInfo]);
        }
    } else {
        NSLog(@"Unresolved error %@, %@, %@", error, [error userInfo], [error localizedDescription]);
    }
}

- (void)_GA_saveContext {
    [self _GA_saveContextShowingSaveMessage:TRUE exitOnError:TRUE];
}

- (void)_GA_saveContextSilent {
    [self _GA_saveContextShowingSaveMessage:FALSE exitOnError:TRUE];
}

- (void)_GA_saveContextShowingSaveMessage:(BOOL)showSaveMessage exitOnError:(BOOL)exitOnError {
    
    @try {
        NSError *error = nil;
        BOOL success = [self save:&error];
        if (!success) {
            // Handle error
            NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
            [self _GA_showErrors:error];
            
            if (exitOnError) {
                NSLog(@"Time to exit");
                exit(-1);  // Fail
            }
        } else {
            if (showSaveMessage) {
                NSLog(@"%@ saved", self);
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception saving: %@", exception);
        abort();
    }
    @finally {

    }
}

@end
