//
//  GASender.h
//  GameAnalytics
//
//  Created by Rick Chapman on 06/03/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GASender : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (void)startWithRequest:(NSURLRequest *)request forEventIDs:(NSArray *)eventIDs;

@end
