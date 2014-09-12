//
//  GAUser+Queries.m
//  GameAnalytics
//
//  Created by Rick Chapman on 14/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "GAUser+Queries.h"
#import "GAEvents+Queries.h"

@implementation GAUser (Queries)

- (NSDictionary *)getDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super getDictionary]];
    
    [dict removeObjectForKey:@"event_id"];
    [dict removeObjectForKey:@"area"];
    [dict removeObjectForKey:@"x"];
    [dict removeObjectForKey:@"y"];
    [dict removeObjectForKey:@"z"];

    if ([self.iosID length]) {
        [dict setValue:self.iosID forKey:@"ios_id"];
    }
    
    if ([self.platform length]) {
        [dict setValue:self.platform forKey:@"platform"];
    }
    
    if ([self.device length]) {
        [dict setValue:self.device forKey:@"device"];
    }
    
    if ([self.osMajor length]) {
        [dict setValue:self.osMajor forKey:@"os_major"];
    }
    
    if ([self.osMinor length]) {
        [dict setValue:self.osMinor forKey:@"os_minor"];
    }
    
    if ([self.installPublisher length]) {
        [dict setValue:self.installPublisher forKey:@"install_publisher"];
    }
    
    if ([self.installSite length]) {
        [dict setValue:self.installSite forKey:@"install_site"];
    }
    
    if ([self.installCampaign length]) {
        [dict setValue:self.installCampaign forKey:@"install_campaign"];
    }
    
    if ([self.installAdgroup length]) {
        [dict setValue:self.installAdgroup forKey:@"install_adgroup"];
    }
    
    if ([self.installAd length]) {
        [dict setValue:self.installAd forKey:@"install_ad"];
    }

    if ([self.installKeyword length]) {
        [dict setValue:self.installKeyword forKey:@"install_keyword"];
    }
    
    if ([self.sdkVersion length]) {
        [dict setValue:self.sdkVersion forKey:@"sdk_version"];
    }
    
    if ([self.gender length]) {
        [dict setValue:self.gender forKey:@"gender"];
    }
    
    if (nil != self.birthYear) {
        [dict setValue:self.birthYear forKey:@"birth_year"];
    }
    
    if (nil != self.friendCount) {
        [dict setValue:self.friendCount forKey:@"friend_count"];
    }
    
    return dict;
}

@end
