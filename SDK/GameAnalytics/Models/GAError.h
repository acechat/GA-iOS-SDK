//
//  GAError.h
//  GameAnalytics
//
//  Created by Rick Chapman on 11/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GAEvents.h"


@interface GAError : GAEvents

@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * severity;

@end
