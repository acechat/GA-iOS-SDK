//
//  GASender.m
//  GameAnalytics
//
//  Created by Rick Chapman on 06/03/2014.
//  Copyright (c) 2014 Rick Chapman. All rights reserved.
//

#import "GASender.h"
#import "GALogger.h"
#import "GABatchController.h"

#import "GACoreDataController.h"
#import "NSManagedObjectContext+Save.h"

#import "GAEvents+Queries.h"

@interface GASender ()

@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSArray *eventIDs;
@property (nonatomic, strong) NSHTTPURLResponse *httpResponse;

@end

@implementation GASender

- (void)startWithRequest:(NSURLRequest *)request forEventIDs:(NSArray *)eventIDs {
    
    self.eventIDs = eventIDs;
    
    // Set the status on these events to prevent any other thread from uploading them
    
    [self setEventStatus:GAStatusTypeSending];

    // Start the connection
    
    self.receivedData = [NSMutableData dataWithCapacity: 0];
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:request
                                                                   delegate:self];
    if (!theConnection) {
        //
        // Problem making commection - Release the receivedData object and
        // inform the user that the connection failed.
        //
        self.receivedData = nil;
        [GALogger w:@"Connection Failed"];

        //
        // Set status back here just in case the delegate doesn't fire
        // May occur under extreme low memory conditions
        //
        [self setEventStatusBasedOnCachingOptions];

    } else {
        [GALogger d:@"Connection Made"];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse object.
    
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    
    [GALogger d:@"GASender connection didReceiveResponse"];
    [self.receivedData setLength:0];
    
    self.httpResponse = (NSHTTPURLResponse *)response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [GALogger d:@"GASender connection didReceiveData"];
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

    connection = nil;
    self.receivedData = nil;
    self.httpResponse = nil;
    
    // inform the user
    [GALogger w:@"Connection failed! Error - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]];

    [self setEventStatusBasedOnCachingOptions];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    //NSLog(@"Succeeded! Received %lu bytes of data",(unsigned long)[self.receivedData length]);
    
    if (self.httpResponse.statusCode == 200) {
        
        //
        // Response was good. Events uploaded. Message user and Set for deletion.
        //
        
        // Grab a context and find the first event by ID to extract type
        NSManagedObjectContext *bgContext = [[GACoreDataController sharedInstance] backgroundContext];

        NSManagedObjectID *myID = [self.eventIDs firstObject];
        GAEvents *event = (GAEvents *)[bgContext objectWithID:myID];
        GAEventType eventType = [event.eventTypeID integerValue];
        NSString *eventStr = [GAEvents eventStringForType:eventType];
        
        [GALogger i:@"Finished sending %lu %@ events.", [self.eventIDs count], eventStr];

        // Now set these events for deletion
        [self setEventStatus:GAStatusTypeReadyToDelete];

    } else {
        
        // Response was an error condition. Show message and reset events
        [self showErrorMessageFromResponse:self.httpResponse withData:self.receivedData];

        [self setEventStatusBasedOnCachingOptions];
    }
    
    [[GABatchController sharedInstance] checkForEventsToDelete];
    
    connection = nil;
    self.receivedData = nil;
    self.httpResponse = nil;
}

- (void)setEventStatusBasedOnCachingOptions {

    // Check if we are caching locally
    GABatchController *bc = [GABatchController sharedInstance];
    if (bc.localCaching) {
        // We are caching so reset these events to try again
        [self setEventStatus:GAStatusTypeNew];
    } else {
        // We are NOT caching so discard these events
        [self setEventStatus:GAStatusTypeReadyToDelete];
    }

}

- (void)setEventStatus:(GAStatusType)targetStatus {
    
    [GALogger d:@"setEventStatus: %ld", (long)targetStatus];

    // Grab a context and find objects by ID
    NSManagedObjectContext *bgContext = [[GACoreDataController sharedInstance] backgroundContext];
    
    for (NSManagedObjectID *myID in self.eventIDs) {
        GAEvents *event = (GAEvents *)[bgContext objectWithID:myID];
        event.status = [NSNumber numberWithInt:targetStatus];
    }
    
    [bgContext _GA_saveContextSilent];
}

- (void)showErrorMessageFromResponse:(NSHTTPURLResponse *)response withData:(NSData *)returnData {
    
    NSNumber *num = [NSNumber numberWithInteger:response.statusCode];
    [GALogger i:@"Response StatusCode: %@", num];

    NSString *errorStr = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    NSString *errorDescription = nil;
    
    switch (response.statusCode) {
        case 400:
            if ([errorStr isEqualToString:GA_BAD_REQUEST]) {
                errorDescription = GA_BAD_REQUEST_DESC;
            } else if ([errorStr isEqualToString:GA_NO_GAME]) {
                errorDescription = GA_NO_GAME_DESC;
            } else if ([errorStr isEqualToString:GA_DATA_NOT_FOUND]) {
                errorDescription = GA_DATA_NOT_FOUND_DESC;
            }
            break;
            
        case 401:
            if ([errorStr isEqualToString:GA_UNAUTHORIZED]) {
                errorDescription = GA_UNAUTHORIZED_DESC;
            } else if ([errorStr isEqualToString:GA_SIG_NOT_FOUND]) {
                errorDescription = GA_SIG_NOT_FOUND_DESC;
            }
            break;
            
        case 403:
            errorDescription = GA_FORBIDDEN_DESC;
            break;
            
        case 404:
            if ([errorStr isEqualToString:GA_GAME_NOT_FOUND]) {
                errorDescription = GA_GAME_NOT_FOUND_DESC;
            } else if ([errorStr isEqualToString:GA_METHOD_NOT_SUPPORTED]) {
                errorDescription = GA_METHOD_NOT_SUPPORTED_DESC;
            }
            break;
            
        case 500:
            errorDescription = GA_INTERNAL_SERVER_ERROR_DESC;
            break;
            
        case 501:
            errorDescription = GA_NOT_IMPLEMENTED_DESC;
            break;
            
        default:
            break;
    }
    
    if ([errorDescription length]) {
        [GALogger e:errorDescription];
    } else {
        NSString *rtnMsg = [NSString stringWithFormat:@"Unrecognized error from Server: %@ : %@", errorStr, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]];
        [GALogger e:rtnMsg];
    }
}


NSString *const GA_BAD_REQUEST = @"Bad request";
NSString *const GA_BAD_REQUEST_DESC = @"When you see this, most likely some required fields are missing from the JSON data you sent. Make sure you include all required fields for the category you are using. Please note that incomplete events are discarded.";
NSString *const GA_NO_GAME = @"Game not found";
NSString *const GA_NO_GAME_DESC = @"The game key supplied was not recognised. Make sure that you use the game key you were supplied when you signed up in [GameAnalytics initialiseWithGameKey::].";
NSString *const GA_DATA_NOT_FOUND = @"Data not found";
NSString *const GA_DATA_NOT_FOUND_DESC = @"No JSON data was sent with the request. Make sure that you are sending some data as either a single JSON object or as an array of JSON objects.";
NSString *const GA_UNAUTHORIZED = @"Unauthorized";
NSString *const GA_UNAUTHORIZED_DESC = @"The value of the authorization header is not valid. Make sure you use exactly the same secret key as was supplied to you when you created your Game Analytics account.";
NSString *const GA_SIG_NOT_FOUND = @"Signature not found in request";
NSString *const GA_SIG_NOT_FOUND_DESC = @"The \"Authorization\" header is missing. Make sure that you add a header with the \"Authorization\" key to your API call.";
NSString *const GA_FORBIDDEN_DESC = @"Make sure that the URL is valid and that it conforms to the specifications.";
NSString *const GA_GAME_NOT_FOUND = @"Game key not found";
NSString *const GA_GAME_NOT_FOUND_DESC = @"The game key in the URL does not match any existing games. Make sure that you are using the correct game key (the key which you received when creating your game on the GameAnalytics website).";
NSString *const GA_METHOD_NOT_SUPPORTED = @"Method not found";
NSString *const GA_METHOD_NOT_SUPPORTED_DESC = @"The URI used to post data to the server was incorrect. This could be because the game key supplied the GameAnalytics during initialise() was blank or null.";
NSString *const GA_INTERNAL_SERVER_ERROR_DESC = @"Internal server error. Please bring this error to Game Analytics attention. We are sorry for any inconvenience caused.";
NSString *const GA_NOT_IMPLEMENTED_DESC = @"The used HTTP method is not supported. Please only use the POST method for submitting data.";

// TODO - Tim's code
NSString *const GA_BAD_REQUEST1 = @"Not all required fields are present in the data.";

@end
