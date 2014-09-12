//
//  GAError+Queries.m
//  GameAnalytics
//
//  Created by Rick Chapman on 14/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "GAError+Queries.h"
#import "GAEvents+Queries.h"

@implementation GAError (Queries)

- (NSDictionary *)getDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super getDictionary]];
    
    [dict removeObjectForKey:@"event_id"];
    
    if ([self.message length]) {
        [dict setValue:self.message forKey:@"message"];
    }
    
    if (nil != self.severity) {
        [dict setValue:self.severity forKey:@"severity"];
    }
    
    return dict;
}

@end
