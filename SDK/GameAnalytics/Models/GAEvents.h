//
//  GAEvents.h
//  GameAnalytics
//
//  Created by Rick Chapman on 04/03/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GAEvents : NSManagedObject

@property (nonatomic, retain) NSString * area;
@property (nonatomic, retain) NSString * build;
@property (nonatomic, retain) NSString * eventID;
@property (nonatomic, retain) NSString * eventType;
@property (nonatomic, retain) NSNumber * eventTypeID;
@property (nonatomic, retain) NSString * gameKey;
@property (nonatomic, retain) NSString * secretKey;
@property (nonatomic, retain) NSString * sessionID;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSNumber * x;
@property (nonatomic, retain) NSNumber * y;
@property (nonatomic, retain) NSNumber * z;
@property (nonatomic, retain) NSNumber * eventIdx;

@end
