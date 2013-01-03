//
//  LocalyticsPlugin.h
//  LocalyticsPhonegapExample
//
//  Copyright 2012 Localytics. All rights reserved.
//


#import "SalesforceHybridSDK/CDVPlugin.h"
#import "LocalyticsSession.h"

@interface LocalyticsPlugin : CDVPlugin

- (void) startSession:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) close:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) upload:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) tagEvent:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void) tagScreen:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end