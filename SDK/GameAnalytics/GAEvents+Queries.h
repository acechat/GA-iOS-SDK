//
//  GAEvents+Queries.h
//  GameAnalytics
//
//  Created by Rick Chapman on 11/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "GAEvents.h"

typedef enum GAEventType : NSInteger {
    GAEventTypeGeneral          = 0,
    GAEventTypeUser             = 1,
    GAEventTypeBusiness         = 2,
    GAEventTypeDesign           = 3,
    GAEventTypeError            = 4,
} GAEventType;

typedef enum GAStatusType : NSInteger {
    GAStatusTypeNew             = 0,
    GAStatusTypeSending         = 1,
    GAStatusTypeUploaded        = 2,
    GAStatusTypeReadyToDelete   = 3,
} GAStatusType;

#define FPS_EVENT_NAME              @"GA:AverageFPS"
#define CRITICAL_FPS_EVENT_NAME     @"GA:CriticalFPS"

@interface GAEvents (Queries)

- (NSDictionary *)getDictionary;
+ (NSString *)eventStringForType:(GAEventType)type;
- (NSNumber *)nextIndexForEntity;

@end
