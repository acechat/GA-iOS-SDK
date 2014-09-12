//
//  NSManagedObjectContext+Save.h
//
//  Created by Rick Chapman on 18/05/2012.
//  Copyright (c) 2012 Parkview Consultants. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (Save)

- (void)_GA_saveContext;
- (void)_GA_saveContextSilent;
- (void)_GA_saveContextShowingSaveMessage:(BOOL)showSaveMessage exitOnError:(BOOL)exitOnError;
- (void)_GA_showErrors:(NSError *)error;

@end
