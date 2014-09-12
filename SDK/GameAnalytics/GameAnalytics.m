//
//  GameAnalytics.m
//  GameAnalytics
//
//  Created by Rick Chapman on 10/02/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "GameAnalytics.h"
#import "GACoreDataController.h"
#import "GALogger.h"
#import "GABatchController.h"

#import "GAEvents+Queries.h"
#import "GABusiness+Queries.h"
#import "GADesign+Queries.h"
#import "GAUser+Queries.h"
#import "GAError+Queries.h"

#import "NSManagedObjectContext+Save.h"

#import <objc/message.h>
#import "NSObject+MD5.h"

@interface GameAnalytics ()

@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, assign) BOOL enableUncaughtExceptionHandler;
@property (nonatomic, strong) NSString *gameKey;
@property (nonatomic, strong) NSString *secretKey;
@property (nonatomic, strong) NSString *build;
@property (nonatomic, strong) NSString *idfa;
@property (nonatomic, strong) NSString *idfv;
@property (nonatomic, assign) BOOL checkedIDFA;
@property (nonatomic, strong) NSString *defaultArea;
@property (nonatomic, strong) NSString *myUserID;

@property (nonatomic, strong) NSString *sessionID;

@property (nonatomic, strong) NSDate *fpsStartTime;
@property (nonatomic, assign) NSInteger fpsFrameCount;
@property (nonatomic, assign) NSTimeInterval fpsMinimumPeriod;
@property (nonatomic, strong) NSNumber *fpsCriticalLimit;

@property (nonatomic, assign) NSInteger maxEventCount;

@end


@implementation GameAnalytics

//---------------------------------------------------------------------------------------------//
#pragma mark -
#pragma mark NSObject lifecycle methods
//---------------------------------------------------------------------------------------------//

+ (GameAnalytics *)sharedInstance {
    static GameAnalytics *_sharedInstanceGA = nil;
    static dispatch_once_t oncePredicateGA;
    dispatch_once(&oncePredicateGA, ^{
        _sharedInstanceGA = [[self alloc] init];
    });
    return _sharedInstanceGA;
}

- (id)init {
    self = [super init];
    if (self) {
        [GALogger setDebugLogging:FALSE];
        
        [GALogger d:@"GameAnalytics Init"];
        
        self.initialized = false;
        self.enableUncaughtExceptionHandler = FALSE;
        self.sessionID = nil;
        self.build = nil;
        self.checkedIDFA = FALSE;
        self.idfa = nil;
        self.idfv = nil;
        self.myUserID = nil;
        
        self.defaultArea = nil;
        
        self.fpsStartTime = nil;
        self.fpsFrameCount = 0;
        self.fpsMinimumPeriod = 5;
        self.fpsCriticalLimit = @20;
        
        self.maxEventCount = 0;
        
        // Start the core data stack
        GACoreDataController *controller = [GACoreDataController sharedInstance];
        controller = nil;
    }
    return self;
}

//---------------------------------------------------------------------------------------------//
#pragma mark -
#pragma mark Engine initialization methods
//---------------------------------------------------------------------------------------------//

void ga_embedded_uncaughtExceptionHandler(NSException *exception) {
    [GALogger e:@"Uncaught Exception: %@", exception];
    [GameAnalytics newErrorEventWithMessage:[exception description] severity:GASeverityTypeCritical];
}

+ (void)enableExceptionHandler:(BOOL)value {
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    
    if (ga.initialized) {
        [GALogger w:@"Warning: GameAnalytics has already been initialised. Call enableExceptionHandler: before initializeWithGameKey:secretKey:"];
        return;
    }

    ga.enableUncaughtExceptionHandler = value;
}

+ (void)startSession {
    [GALogger i:@"GameAnalytics startSession"];
    
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    GABatchController *bc = [GABatchController sharedInstance];

    [ga getSessionID];
    [bc run];
}

+ (NSString *)defaultBuild {
   
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    if (![build length]) {
        [GALogger w:@"CFBundleVersion was not found in the application info.plist"];
        build = @"unknown";
    }
    
    return build;
}

+ (void)initializeWithGameKey:(NSString *)gameKey secretKey:(NSString *)secretKey build:(NSString *)build {

    GameAnalytics *ga = [GameAnalytics sharedInstance];
    if (ga.enableUncaughtExceptionHandler) {
        NSSetUncaughtExceptionHandler(&ga_embedded_uncaughtExceptionHandler);
    }
    
    [GALogger d:@"GameAnalytics initializeGameKey"];
    
    ga.gameKey = gameKey;
    ga.secretKey = secretKey;
    ga.build = [build length] ? build : [GameAnalytics defaultBuild];

    // Initialise a GABatchController, but don't run yet
    GABatchController *bc = [GABatchController sharedInstance];
    bc = nil;
    
    ga.initialized = TRUE;
    
    [GameAnalytics startSession];
}

+ (void)initializeWithGameKey:(NSString *)gameKey secretKey:(NSString *)secretKey {

    NSString *build = [GameAnalytics defaultBuild];
    
    [GameAnalytics initializeWithGameKey:gameKey secretKey:secretKey build:build];
}

//---------------------------------------------------------------------------------------------//
#pragma mark -
#pragma mark Build session and standard variables methods
//---------------------------------------------------------------------------------------------//

- (NSString *)getGameUUIDKey {
    NSString *myUUIDstr = @"GA_UUID_";
    myUUIDstr = [myUUIDstr stringByAppendingString:self.gameKey];
    myUUIDstr = [myUUIDstr stringByAppendingString:@"_"];
    myUUIDstr = [myUUIDstr stringByAppendingString:self.secretKey];
    return  myUUIDstr;
}

- (NSString *)getIDFV {
    
    if (nil != self.idfv) {
        return self.idfv;
    }

    if (floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_6_0) {
        // Load resources for iOS 5.1 or earlier
        
        NSString *uuidKey = [self getGameUUIDKey];
        [GALogger d:@"Pre iOS6 - Search for UUID in User Defaults - Key: %@", uuidKey];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *appUID = [defaults objectForKey:uuidKey];
        if (appUID == nil) {

            // generate a new uuid and store it in user defaults
            [GALogger d:@"Pre iOS6 - No UUID in User Defaults - Generate new one"];
            CFUUIDRef uuid = CFUUIDCreate(NULL);
            appUID = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
            
            [GALogger d:@"Pre iOS6 - No UUID in User Defaults - Generated new one: %@", appUID];
            
            [defaults setObject:appUID forKey:uuidKey];
            [defaults synchronize];
            CFRelease(uuid);
            
        } else {
            [GALogger d:@"Retreived UUID from User Defaults: %@", appUID];
        }

        self.idfv = appUID;
        
    } else {
        // Load resources for iOS 6 or later
        
        NSUUID *uid = [[UIDevice currentDevice] identifierForVendor];
        self.idfv = uid.UUIDString;

    }
    
    [GALogger i:@"IDFV generated: %@", self.idfv];
    
    return self.idfv;
}

- (NSString *)getIDFA {
    
    if (self.checkedIDFA) {
        return self.idfa;
    }
    
    self.checkedIDFA = TRUE;
    
    if (nil == NSClassFromString(@"ASIdentifierManager")) {
        [GALogger d:@"GameAnalytics: No Ad Framework present, Will use IDFV"];
        return nil;
    }
    
    Class abstractClass = NSClassFromString(@"ASIdentifierManager");
    NSObject *obj = [[abstractClass alloc] init];
    
    SEL mySelector = @selector(advertisingIdentifier);
    
    if ([obj respondsToSelector:mySelector]) {
        [GALogger d:@"GameAnalytics Found Ad Framework"];
    }
    
    NSUUID *uid = (NSUUID *) objc_msgSend(obj, mySelector);
    self.idfa = uid.UUIDString;
    
    [GALogger i:@"IDFA generated: %@", self.idfa];

    return self.idfa;
}

- (NSString *)getUserID {
    if (nil != self.myUserID) {
        return self.myUserID;
    }

    self.myUserID = [self getIDFA];
    
    if (nil == self.myUserID) {
        self.myUserID = [self getIDFV];
    }
    
    return self.myUserID;
}

+ (NSString *)getUserID {
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    
    if (nil == ga.myUserID) {
        [GALogger w:@"Warning: UserID has not been initialised. Either call initializeWithGameKey:secretKey: or setUserID: first"];
        return nil;
    }
    
    return [ga getUserID];
}

+ (void)setUserID:(NSString *)userID {
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    ga.myUserID = userID;
}

- (NSString *)getSessionID {
    
    if ([[GABatchController sharedInstance] hasSessionTimedOut]) {
        // We need a new SessionID
        self.sessionID = nil;
    }
    
    if (nil != self.sessionID) {
        return self.sessionID;
    }
    
    NSString *userID = [self getUserID];
    NSDate *date = [NSDate date];
    NSTimeInterval ti = [date timeIntervalSince1970];
    NSString *myId = [NSString stringWithFormat:@"%@%lf", userID, ti * 1000];
    
    self.sessionID = [myId _GA_md5];
    
    [GALogger i:@"SessionID generated: %@", self.sessionID];

    [self sendOffUserStats];

    return self.sessionID;
}

+ (void)updateSessionID {
    
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    ga.sessionID = nil;
    
    [ga getSessionID];
}

//---------------------------------------------------------------------------------------------//
#pragma mark -
#pragma mark Event Logging methods
//---------------------------------------------------------------------------------------------//

- (BOOL)dbIsFull {

    if (self.maxEventCount == 0) {
        return FALSE;
    }
    
    NSInteger dbCount = [[GABatchController sharedInstance] countAllEvents];
    if (dbCount >= self.maxEventCount) {
        [GALogger i:@"Database is full (setMaximumEventStorage:). Event will be discarded"];
        return TRUE;
    }
    
    return FALSE;
}

- (void)addStandardParamsToEvent:(GAEvents *)event {
    event.gameKey = self.gameKey;
    event.secretKey = self.secretKey;
    
    event.userID = [self getUserID];
    event.sessionID = [self getSessionID];
    event.build = self.build;
    
    event.status = [NSNumber numberWithInt:GAStatusTypeNew];

    event.eventIdx = [event nextIndexForEntity];
}

+ (void)newBusinessEventWithId:(NSString *)eventId currency:(NSString *)currency amount:(NSNumber *)amount area:(NSString *)area x:(NSNumber *)x y:(NSNumber *)y z:(NSNumber *)z {
    
    NSString *str = [NSString stringWithFormat:@"New business event: %@, currency: %@, amount: %@, area: %@, pos: (%@, %@, %@)", eventId, currency, amount, area, x, y, z];
    [GALogger i:str];

    // Add event to database
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    if ([ga dbIsFull]) {
        return;
    }

    NSManagedObjectContext *bgContext = [[GACoreDataController sharedInstance] backgroundContext];
    GABusiness *event = [NSEntityDescription insertNewObjectForEntityForName:@"GABusiness" inManagedObjectContext:bgContext];
    
    [ga addStandardParamsToEvent:event];
    
    event.eventType = [GAEvents eventStringForType:GAEventTypeBusiness];
    event.eventTypeID = [NSNumber numberWithInt:GAEventTypeBusiness];
    
    event.eventID = eventId;
    event.currency = currency;
    event.amount = amount;
    
    if (nil != area) event.area = area;
    if (nil != x) event.x = x;
    if (nil != y) event.y = y;
    if (nil != z) event.z = z;
        
    [bgContext _GA_saveContextSilent];
}

+ (void)newBusinessEventWithId:(NSString *)eventId currency:(NSString *)currency amount:(NSNumber *)amount {
    [GameAnalytics newBusinessEventWithId:eventId currency:currency amount:amount area:nil x:nil y:nil z:nil];
}

+ (void)newDesignEventWithId:(NSString *)eventId value:(NSNumber *)value area:(NSString *)area x:(NSNumber *)x y:(NSNumber *)y z:(NSNumber *)z {

    NSString *str = [NSString stringWithFormat:@"New design event: %@, value: %@, area: %@, pos: (%@, %@, %@)", eventId, value, area, x, y, z];
    [GALogger i:str];

    // Add event to database
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    if ([ga dbIsFull]) {
        return;
    }

    NSManagedObjectContext *bgContext = [[GACoreDataController sharedInstance] backgroundContext];
    GADesign *event = [NSEntityDescription insertNewObjectForEntityForName:@"GADesign" inManagedObjectContext:bgContext];
    
    [ga addStandardParamsToEvent:event];
    
    event.eventType = [GAEvents eventStringForType:GAEventTypeDesign];
    event.eventTypeID = [NSNumber numberWithInt:GAEventTypeDesign];
    
    event.eventID = eventId;
    event.value = value;
    
    if (nil != area) event.area = area;
    if (nil != x) event.x = x;
    if (nil != y) event.y = y;
    if (nil != z) event.z = z;
    
    [bgContext _GA_saveContextSilent];
}

+ (void)newDesignEventWithId:(NSString *)eventId value:(NSNumber *)value {
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    [GameAnalytics newDesignEventWithId:eventId value:value area:ga.defaultArea x:nil y:nil z:nil];
}

+ (void)newDesignEventWithId:(NSString *)eventId {
    [GameAnalytics newDesignEventWithId:eventId value:nil];
}

+ (void)newErrorEventWithMessage:(NSString *)message severity:(GASeverityType)severity area:(NSString *)area x:(NSNumber *)x y:(NSNumber *)y z:(NSNumber *)z {
    
    NSArray *severityMsgs = @[@"critical", @"error", @"warning", @"info", @"debug"];

    if (severity < GASeverityTypeCritical || severity > GASeverityTypeDebug) {
        [GALogger w:@"Warning: unsupported severity level passed into newErrorEventWithMessage:, use a valid GASeverityType."];
        return;
    }
    
    NSString *str = [NSString stringWithFormat:@"New error event: message: %@, severity: %@, area: %@, pos: (%@, %@, %@)", message, [severityMsgs objectAtIndex:severity], area, x, y, z];
    [GALogger i:str];
    
    // Add event to database
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    if ([ga dbIsFull]) {
        return;
    }

    NSManagedObjectContext *bgContext = [[GACoreDataController sharedInstance] backgroundContext];
    GAError *event = [NSEntityDescription insertNewObjectForEntityForName:@"GAError" inManagedObjectContext:bgContext];
    
    [ga addStandardParamsToEvent:event];
    
    event.eventType = [GAEvents eventStringForType:GAEventTypeError];
    event.eventTypeID = [NSNumber numberWithInt:GAEventTypeError];
    
    event.message = message;
    event.severity = [severityMsgs objectAtIndex:severity];
    
    if (nil != area) event.area = area;
    if (nil != x) event.x = x;
    if (nil != y) event.y = y;
    if (nil != z) event.z = z;
    
    [bgContext _GA_saveContextSilent];
}

+ (void)newErrorEventWithMessage:(NSString *)message severity:(GASeverityType)severity {
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    [GameAnalytics newErrorEventWithMessage:message severity:severity area:ga.defaultArea x:nil y:nil z:nil];
}

+ (void)newUserEventWithGender:(NSString *)gender birthYear:(NSNumber *)birthYear friendCount:(NSNumber *)friendCount area:(NSString *)area x:(NSNumber *)x y:(NSNumber *)y z:(NSNumber *)z platform:(NSString *)platform device:(NSString *)device osMajor:(NSString *)osMajor osMinor:(NSString *)osMinor sdkVersion:(NSString *)sdkVersion installPublisher:(NSString *)installPublisher installSite:(NSString *)installSite installCampaign:(NSString *)installCampaign installAdgroup:(NSString *)installAdgroup installAd:(NSString *)installAd installKeyword:(NSString *)installKeyword {
    
    NSString *str = [NSString stringWithFormat:@"New user event: gender: %@, birthYear: %@, area: %@, pos: (%@, %@, %@), platform: %@, device: %@, osMajor: %@, osMinor: %@, sdkVersion: %@, installPublisher: %@, installSite: %@, installCampaign: %@, installAdgroup: %@, installAd: %@, installKeyword: %@", gender, birthYear, area, x, y, z, platform, device, osMajor, osMinor, sdkVersion, installPublisher, installSite, installCampaign, installAdgroup, installAd, installKeyword];
    [GALogger i:str];
    
    // Add event to database
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    if ([ga dbIsFull]) {
        return;
    }

    NSManagedObjectContext *bgContext = [[GACoreDataController sharedInstance] backgroundContext];
    GAUser *event = [NSEntityDescription insertNewObjectForEntityForName:@"GAUser" inManagedObjectContext:bgContext];
    
    [ga addStandardParamsToEvent:event];
    
    event.eventType = [GAEvents eventStringForType:GAEventTypeUser];
    event.eventTypeID = [NSNumber numberWithInt:GAEventTypeUser];
    
    event.gender = gender;
    event.birthYear = birthYear;
    event.friendCount = friendCount;
    
    event.platform = platform;
    event.device = device;
    event.osMajor = osMajor;
    event.osMinor = osMinor;
    event.sdkVersion = sdkVersion;
    event.installPublisher = installPublisher;
    event.installSite = installSite;
    event.installCampaign = installCampaign;
    event.installAdgroup = installAdgroup;
    event.installAd = installAd;
    event.installKeyword = installKeyword;
    
    if ([ga getIDFA]) {
        event.iosID = [ga getIDFA];
    }
    
    if (nil != area) event.area = area;
    if (nil != x) event.x = x;
    if (nil != y) event.y = y;
    if (nil != z) event.z = z;
    
    [bgContext _GA_saveContextSilent];
}

+ (void)setUserInfoWithGender:(NSString *)gender birthYear:(NSNumber *)birthYear friendCount:(NSNumber *)friendCount {
    
    GameAnalytics *ga = [GameAnalytics sharedInstance];

    [GameAnalytics newUserEventWithGender:gender birthYear:birthYear friendCount:friendCount area:ga.defaultArea x:nil y:nil z:nil platform:nil device:nil osMajor:nil osMinor:nil sdkVersion:nil installPublisher:nil installSite:nil installCampaign:nil installAdgroup:nil installAd:nil installKeyword:nil];
}

+ (void)setReferralInfoWithPublisher:(NSString *)installPublisher installSite:(NSString *)installSite installCampaign:(NSString *)installCampaign installAdgroup:(NSString *)installAdgroup installAd:(NSString *)installAd installKeyword:(NSString *)installKeyword {

    GameAnalytics *ga = [GameAnalytics sharedInstance];

    [GameAnalytics newUserEventWithGender:nil birthYear:nil friendCount:nil area:ga.defaultArea x:nil y:nil z:nil platform:nil device:nil osMajor:nil osMinor:nil sdkVersion:nil installPublisher:installPublisher installSite:installSite installCampaign:installCampaign installAdgroup:installAdgroup installAd:installAd installKeyword:installKeyword];
}

- (void)sendOffUserStats {
    
    UIDevice *thisDevice = [UIDevice currentDevice];
    
    //NSString *platform = [thisDevice systemName];
    NSString *platform = @"iOS";
    NSString *device = [thisDevice model];

    // osMinor = 7.0.3, osMajor = 7
    NSString *osMinor = [thisDevice systemVersion];
    NSString *osMajor = [osMinor componentsSeparatedByString:@"."][0];
    
    NSString *sdkVersion = GA_SDK_VERSION;
    
    NSString *area = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    self.defaultArea = area;
    
    [GameAnalytics newUserEventWithGender:nil birthYear:nil friendCount:nil area:area x:nil y:nil z:nil platform:platform device:device osMajor:osMajor osMinor:osMinor sdkVersion:sdkVersion installPublisher:nil installSite:nil installCampaign:nil installAdgroup:nil installAd:nil installKeyword:nil];
    
}

//---------------------------------------------------------------------------------------------//
#pragma mark -
#pragma mark Batch control and utility methods
//---------------------------------------------------------------------------------------------//

+ (void)setAutoBatch:(BOOL)value {
    GABatchController *bc = [GABatchController sharedInstance];
    bc.autoBatch = value;
}

+ (void)manualBatch {
    [[GABatchController sharedInstance] sendManualBatch];
}

+ (void)setLocalCaching:(BOOL)value {
    GABatchController *bc = [GABatchController sharedInstance];
    bc.localCaching = value;
}

+ (void)setSessionTimeOut:(NSTimeInterval)seconds {
    GABatchController *bc = [GABatchController sharedInstance];
    bc.sessionTimeoutDuration = seconds;
}

+ (void)setSendEventsInterval:(NSTimeInterval)seconds {
    GABatchController *bc = [GABatchController sharedInstance];
    bc.sendEventInterval = seconds;
}

+ (void)clearDatabase {
    [GALogger d:@"clearDatabase"];
    [GABatchController deleteAllEvents];
}

+ (void)setDebugLogLevelVerbose:(BOOL)level {
    [GALogger d:@"setDebugLogLevelVerbose: %@", level ? @"TRUE" : @"FALSE"];
    [GALogger setVerbose:level];
}

+ (void)setMaximumEventStorage:(NSInteger)maxEvents {
    [GALogger d:@"setMaximumEventStorage: %ld", maxEvents];

    GameAnalytics *ga = [GameAnalytics sharedInstance];
    ga.maxEventCount = maxEvents;
}

//---------------------------------------------------------------------------------------------//
#pragma mark -
#pragma mark FPS logging methods
//---------------------------------------------------------------------------------------------//

+ (void)logFPS {
    
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    
    // Have we already started logging FPS?
    if (nil == ga.fpsStartTime) {
        // No, start logging
        [GALogger i:@"Start logging FPS."];
        ga.fpsStartTime = [NSDate date];
    }

    // Increment number of frames
    ga.fpsFrameCount++ ;
}

+ (void)stopLoggingFPSForArea:(NSString *)area x:(NSNumber *)x y:(NSNumber *)y z:(NSNumber *)z {
    
    [GALogger i:@"Stop logging FPS."];

    GameAnalytics *ga = [GameAnalytics sharedInstance];

    // Ensure we are logging FPS?

    if (nil != ga.fpsStartTime) {
        
        // Get elapsed time
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:ga.fpsStartTime];
        
        // Has enough time elapsed?
        if (elapsed > ga.fpsMinimumPeriod) {
            
            // Work out average FPS and send
            float fpsFrameCount = (float)ga.fpsFrameCount;
            float fps = (float) (fpsFrameCount / elapsed);
            
            [GameAnalytics newDesignEventWithId:FPS_EVENT_NAME value:@(fps) area:area x:x y:y z:z];
            
            if (fps < [ga.fpsCriticalLimit floatValue]) {
                // FPS is below critical limit
                [GameAnalytics newDesignEventWithId:CRITICAL_FPS_EVENT_NAME value:@(fps) area:area x:x y:y z:z];
            }
            
        } else {
            
            [GALogger w:@"Warning: Insufficient time elapsed between starting and stopping FPS logging."];
        }
        
        ga.fpsStartTime = nil;
        ga.fpsFrameCount = 0;

    } else {
        
        [GALogger w:@"Warning: stopLoggingFPS was called before logging was started with a logFPS call."];

    }

}

+ (void)stopLoggingFPS {
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    [GameAnalytics stopLoggingFPSForArea:ga.defaultArea x:nil y:nil z:nil];
}

+ (void)setCriticalFPSLimit:(NSNumber *)criticalFPS {
    
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    ga.fpsCriticalLimit = criticalFPS;
}

+ (void)setMinimumFPSTimePeriod:(NSTimeInterval)minimumTimePeriod {
    
    GameAnalytics *ga = [GameAnalytics sharedInstance];
    ga.fpsMinimumPeriod = minimumTimePeriod;
}

@end
