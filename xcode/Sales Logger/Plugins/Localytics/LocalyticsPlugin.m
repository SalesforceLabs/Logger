//
//  LocalyticsPlugin.m
//  LocalyticsPhonegapExample
//
//  Copyright 2012 Localytics. All rights reserved.
//

#import "LocalyticsPlugin.h"

#define EVENT_NAME_STRING @"_event_name_"

@implementation LocalyticsPlugin

// Opens a new Localytics Session and causes an upload to occur.
- (void) startSession:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    [[LocalyticsSession sharedLocalyticsSession] startSession:[arguments objectAtIndex:1]];
}

// Closes the session. This should be called on app exit
- (void) close:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    [[LocalyticsSession sharedLocalyticsSession] close];
}

// Forces an upload. This is called automatically by startSession but there are times when others may want to create more
- (void) upload:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    [[LocalyticsSession sharedLocalyticsSession] upload];
}

// Records an event. Assumes the event name and any attributes (optional) are passed along in the options hash.
- (void) tagEvent:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    // Grab the event name from the options array
    NSString *eventName = [options objectForKey:EVENT_NAME_STRING] ?: @"";
    NSMutableDictionary *attributes = nil;
    
    // Loop through every non-event key in the options array and use that to construct the attributes dictionary
    if([options count] > 1)
    {
        attributes = [[NSMutableDictionary alloc] init];
        
        NSEnumerator *enumerator = [options keyEnumerator];
        NSString *key;
        while (key = [ enumerator nextObject]) {
            if(![key isEqualToString:EVENT_NAME_STRING])
            {
                [attributes setObject:[options objectForKey:key] forKey:key];
            }            
        }        
    }
    
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:eventName attributes:attributes];
    
    if(attributes != nil)
    {
        [attributes release];
    }    
}

// Tags a screen. 
- (void) tagScreen:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    [[LocalyticsSession sharedLocalyticsSession] tagScreen:[arguments objectAtIndex:1]];
}

@end