//
//  Created by Björn Sållarp on 2009-06-14.
//  NO Copyright 2009 MightyLittle Industries. NO rights reserved.
// 
//  Use this code any way you like. If you do like it, please
//  link to my blog and/or write a friendly comment. Thank you!
//
//  Read my blog @ http://blog.sallarp.com
//

#import "GACoreDataHelper.h"

@implementation GACoreDataHelper

+ (NSArray *)searchObjectsInContext:(NSManagedObjectContext *)managedObjectContext 
                                entityName:(NSString *)entityName 
                                 predicate:(NSPredicate *)predicate 
                                   sortKey:(NSString *)sortKey 
                             sortAscending:(BOOL)sortAscending {
    
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName 
                                              inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];	
	
	// If a predicate was passed, pass it to the query
	if (predicate != nil) {
		[request setPredicate:predicate];
	}
	
	// If a sort key was passed, use it for sorting.
	if(sortKey != nil) {
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:sortAscending];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		[request setSortDescriptors:sortDescriptors];
	}
	
	NSError *error = nil;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);        
    }
	return fetchResults;
}

+ (NSMutableArray *)searchMutableObjectsInContext:(NSManagedObjectContext *)managedObjectContext 
                                       entityName:(NSString *)entityName 
                                        predicate:(NSPredicate *)predicate 
                                          sortKey:(NSString *)sortKey 
                                    sortAscending:(BOOL)sortAscending {
    
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName 
                                              inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];	
	
	// If a predicate was passed, pass it to the query
	if (predicate != nil) {
		[request setPredicate:predicate];
	}
	
	// If a sort key was passed, use it for sorting.
	if(sortKey != nil) {
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:sortAscending];
		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
		[request setSortDescriptors:sortDescriptors];
	}
	
	NSError *error = nil;	
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (error) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);        
    }

	return mutableFetchResults;
}


+ (NSMutableArray *)getObjectsFromContext:(NSManagedObjectContext *)managedObjectContext 
                               entityName:(NSString *)entityName 
                                  sortKey:(NSString *)sortKey 
                            sortAscending:(BOOL)sortAscending {
    
    return [self searchObjectsInContext:managedObjectContext 
                             entityName:entityName 
                              predicate:nil 
                                sortKey:sortKey 
                          sortAscending:sortAscending];
}


@end
