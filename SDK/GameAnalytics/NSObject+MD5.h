//
//  NSObject+MD5.h
//  GameAnalytics
//
//  Created by Rick Chapman on 11/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MyExtensions)
- (NSString *)_GA_md5;
@end

@interface NSData (MyExtensions)
- (NSString*)_GA_md5;
@end