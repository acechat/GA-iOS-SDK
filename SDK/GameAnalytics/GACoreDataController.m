//
//  GACoreDataController.m
//  GameAnalytics
//
//  Created by Rick Chapman on 10/02/2014.
//
//

#import "GACoreDataController.h"
#import "GALogger.h"

#define kSQLFileName    @"gameanalytics1.sqlite"
#define kModelFileName  @"GameAnalytics1"

@implementation GACoreDataController

+ (GACoreDataController *)sharedInstance {
    static GACoreDataController *_sharedInstanceCDC = nil;
    static dispatch_once_t oncePredicateCDC;
    dispatch_once(&oncePredicateCDC, ^{
        _sharedInstanceCDC = [[self alloc] init];
    });
    return _sharedInstanceCDC;
}

- (id)init {
    self = [super init];
    if (self) {
        [GALogger d:@"GACoreDataController Init"];
        NSManagedObjectContext *moc = self.managedObjectContext;
        moc = nil;
        
        // subscribe to change notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_mocDidSaveNotification:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:nil];
    }
    return self;
}

- (NSManagedObjectContext *)backgroundContext {
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        
        NSManagedObjectContext *bgContext = [[NSManagedObjectContext alloc] init];
        [bgContext setPersistentStoreCoordinator:coordinator];
        [bgContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];

        return bgContext;
    }
    return nil;
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
	
    [GALogger d:@"create managedObjectContext"];
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
        [_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    }
    [GALogger d:@"created managedObjectContext"];
    return _managedObjectContext;
}

- (void)_mocDidSaveNotification:(NSNotification *)notification {
    [GALogger d:@"AppDelegate Merge..."];
    //DebugLog(@"AppDelegate Merge...%@", notification);
    
    NSManagedObjectContext *savedContext = [notification object];
    
    // ignore change notifications for the main MOC
    if (self.managedObjectContext == savedContext) {
        return;
    }
    
    if (self.managedObjectContext.persistentStoreCoordinator != savedContext.persistentStoreCoordinator) {
        // that's another database
        return;
    }
    
    // Merge changes into the main context on the main thread
    [self.managedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                                withObject:notification
                                             waitUntilDone:YES];
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel {
    
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    [GALogger d:@"create managedObjectModel"];

    NSBundle *GABundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"GAResources" withExtension:@"bundle"]];
    NSURL *modelURL = [GABundle URLForResource:kModelFileName withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    [GALogger d:@"created managedObjectModel"];
    [GALogger d:[modelURL path]];

    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSError *error = nil;
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:kSQLFileName];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @YES, NSMigratePersistentStoresAutomaticallyOption,
                             @YES, NSInferMappingModelAutomaticallyOption,
                             nil];

    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {

        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
