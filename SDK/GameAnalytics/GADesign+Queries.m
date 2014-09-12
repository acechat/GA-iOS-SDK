//
//  GADesign+Queries.m
//  GameAnalytics
//
//  Created by Rick Chapman on 14/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "GADesign+Queries.h"
#import "GAEvents+Queries.h"

@implementation GADesign (Queries)

- (NSDictionary *)getDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super getDictionary]];
    
    if (nil != self.value) {
        [dict setValue:self.value forKey:@"value"];
    }
    
    return dict;
}

@end
