//
//  GAEvents+Queries.m
//  GameAnalytics
//
//  Created by Rick Chapman on 11/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "GAEvents+Queries.h"
#import "GALogger.h"

@implementation GAEvents (Queries)

- (NSDictionary *)getDictionary {

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"user_id": self.userID,
                                                                                @"session_id": self.sessionID,
                                                                                @"build": self.build}];
    
    if ([self.area length]) {
        [dict setValue:self.area forKey:@"area"];
    }
    
    if ([self.eventID length]) {
        [dict setValue:self.eventID forKey:@"event_id"];
    }
    
    if (nil != self.x) {
        [dict setValue:self.x forKey:@"x"];
    }
    
    if (nil != self.y) {
        [dict setValue:self.y forKey:@"y"];
    }
    
    if (nil != self.z) {
        [dict setValue:self.z forKey:@"z"];
    }
    
    return dict;
}

+ (NSString *)eventStringForType:(GAEventType)type {

    switch (type) {
        case GAEventTypeBusiness:
            return @"business";
            break;
        
        case GAEventTypeUser:
            return @"user";
            break;
        
        case GAEventTypeDesign:
            return @"design";
            break;
        
        case GAEventTypeError:
            return @"error";
            break;
        
        default:
            return @"unknown";
            break;
    }
    
    return nil;
}

- (NSNumber *)nextIndexForEntity {
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *res = [NSEntityDescription entityForName:@"GAEvents" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:res];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"eventIdx" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    [request setFetchLimit:1];
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (results == nil) {
        [GALogger d:@"First instance"];
    }
    
    NSInteger maximumValue = 0;
    if (results.count == 1) {
        id result = (NSManagedObject *)[results firstObject];
        maximumValue =  [[result valueForKey:@"eventIdx"] integerValue];
    }
    
    maximumValue++ ;
    
    [GALogger d:@"New index: %ld", (long)maximumValue];
    
    return [NSNumber numberWithInteger:maximumValue];
}

@end
