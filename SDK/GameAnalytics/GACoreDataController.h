//
//  GACoreDataController.h
//  GameAnalytics
//
//  Created by Rick Chapman on 10/02/2014.
//
//

#import <Foundation/Foundation.h>

@interface GACoreDataController : NSObject

+ (GACoreDataController *)sharedInstance;

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSManagedObjectContext *)backgroundContext;

@end
