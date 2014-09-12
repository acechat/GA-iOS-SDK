//
//  Created by Björn Sållarp on 2009-06-14.
//  NO Copyright 2009 MightyLittle Industries. NO rights reserved.
// 
//  Use this code any way you like. If you do like it, please
//  link to my blog and/or write a friendly comment. Thank you!
//
//  Read my blog @ http://blog.sallarp.com
//
// Converted to ARC - RSC, 18/3/2012
//

@interface GACoreDataHelper : NSObject {
}

+ (NSMutableArray *)searchObjectsInContext:(NSManagedObjectContext *)managedObjectContext 
                                entityName:(NSString *)entityName 
                                 predicate:(NSPredicate *)predicate 
                                   sortKey:(NSString *)sortKey 
                             sortAscending:(BOOL)sortAscending;

+ (NSMutableArray *)getObjectsFromContext:(NSManagedObjectContext *)managedObjectContext 
                               entityName:(NSString *)entityName 
                                  sortKey:(NSString *)sortKey 
                            sortAscending:(BOOL)sortAscending;

@end
