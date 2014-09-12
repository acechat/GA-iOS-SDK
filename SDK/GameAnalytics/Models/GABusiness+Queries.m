//
//  GABusiness+Queries.m
//  GameAnalytics
//
//  Created by Rick Chapman on 11/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "GABusiness+Queries.h"
#import "GAEvents+Queries.h"

@implementation GABusiness (Queries)

- (NSDictionary *)getDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super getDictionary]];
    
    if ([self.currency length]) {
        [dict setValue:self.currency forKey:@"currency"];
    }
    
    if (nil != self.amount) {
        [dict setValue:self.amount forKey:@"amount"];
    }

    return dict;
}

@end
