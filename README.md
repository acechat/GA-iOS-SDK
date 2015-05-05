> :information_source:<br>
> This SDK is implementing the **V1 API** version of GameAnalytics.<br>
> The **V2 API** version can be found [here](https://github.com/GameAnalytics/GA-SDK-IOS).<br>
> It adds features like progression, validated purchases and virtual currency tracking.<br>
> The [SDK update FAQ](http://www.gameanalytics.com/docs/sdk-update-faq/) contain updated information about future V2 SDK releases.

<br>

GA-iOS-SDK (V1 API)
==============

**Changelog**

**1.0.2**

- Reduced time between changing event status to sent and sending data to server.
- Reset any events with status 'sending' to 'new' on launch.
- SDK handles case when build is supplied as nil.

**1.0.1**

- Pushed source and latest libary file to public repository
- Changed sdk_version, os_major and os_minor fields to match other SDK versions
- Added an updateSessionID method

**1.0.0**

- initial commit of the SDK library

###Set-up

Import the library by following the instructions [here](http://support.gameanalytics.com/hc/en-us/articles/201813726-Download-and-setup).

Initialise using the following:

    [GameAnalytics setDebugLogLevelVerbose:TRUE];
    [GameAnalytics initializeWithGameKey:@"xxx" secretKey:@"xxx"];

###Command List

The rest of the commands are well documented in the header file. They are listed below for convenience:

####Events
    [GameAnalytics newDesignEventWithId:@"PickAmmo:Bullets" value:@25];
    [GameAnalytics newBusinessEventWithId:@"PurchaseCoins" currency:@"USD" amount:@999];
    [GameAnalytics setUserInfoWithGender:@"M" birthYear:@1977 friendCount:@7];
    [GameAnalytics setReferralInfoWithPublisher:@"ChartBoost" installSite:@"Facebook" installCampaign:@"Launch" installAdgroup:nil installAd:@"Launch Ad 1" installKeyword:nil];
    [GameAnalytics newErrorEventWithMessage:@"Game Stalled" severity:GASeverityTypeError];

####FPS
    [GameAnalytics logFPS];
    [GameAnalytics stopLoggingFPS];
    [GameAnalytics setMinimumFPSTimePeriod:10];
    [GameAnalytics setCriticalFPSLimit:15];

####Database options
    [GameAnalytics setLocalCaching:FALSE];
    [GameAnalytics setMaximumEventStorage:6];
    [GameAnalytics clearDatabase];

####Batching options
    [GameAnalytics setAutoBatch:FALSE];
    [GameAnalytics manualBatch];
    [GameAnalytics setSendEventsInterval:10];

####Other
    [GameAnalytics enableExceptionHandler:TRUE];
    [GameAnalytics setSessionTimeOut:10];
    [GameAnalytics getUserID];
    [GameAnalytics setUserID:@"bob127"];
