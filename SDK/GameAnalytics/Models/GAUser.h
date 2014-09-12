//
//  GAUser.h
//  GameAnalytics
//
//  Created by Rick Chapman on 11/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GAEvents.h"


@interface GAUser : GAEvents

@property (nonatomic, retain) NSString * iosID;
@property (nonatomic, retain) NSNumber * birthYear;
@property (nonatomic, retain) NSString * device;
@property (nonatomic, retain) NSNumber * friendCount;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * installAd;
@property (nonatomic, retain) NSString * installAdgroup;
@property (nonatomic, retain) NSString * installCampaign;
@property (nonatomic, retain) NSString * installKeyword;
@property (nonatomic, retain) NSString * installPublisher;
@property (nonatomic, retain) NSString * installSite;
@property (nonatomic, retain) NSString * osMajor;
@property (nonatomic, retain) NSString * osMinor;
@property (nonatomic, retain) NSString * platform;
@property (nonatomic, retain) NSString * sdkVersion;

@end
