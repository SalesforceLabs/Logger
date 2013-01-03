/*
 Copyright (c) 2011-2012, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AppDelegate.h"
#import "Appirater.h"
#import "SalesforceHybridSDK/SFHybridViewController.h"


@interface LoggerViewController : SFHybridViewController
@end

@implementation LoggerViewController

/**
 * Fail Loading With Error
 * Error - If the webpage failed to load display an error with the reason.
 */
- (void)webView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error 
{
    if ([error code] != -999) {
        return [ super webView:theWebView didFailLoadWithError:error ];
    }
}

@end

@implementation AppDelegate

@synthesize splashImageView;


+ (NSString *) startPage 
{
    return @"index.html";
}

#pragma mark - App lifecycle

- (void)configureHybridViewController 
{
    self.viewController = [[[LoggerViewController alloc] init] autorelease];
}

/**
 * This is main kick off after the app inits, the views and Settings are setup here. (preferred - iOS4 and up)
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    @try {
        [[LocalyticsSession sharedLocalyticsSession] startSession:@"LOCALYTICS_KEY"];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e); 
    }
    
    // Initializing appirater for rating Logger
    [Appirater setAppId:@"555411241"];
    [Appirater setDaysUntilPrompt:1];
    [Appirater setUsesUntilPrompt:10];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
 
    //[TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
    //[TestFlight takeOff:@"6c74a7b8a5853ae4e32b32d9fa806e32_ODQ4NjIyMDEyLTA0LTI2IDE0OjM4OjU0Ljk2MDg5NQ"];
    self.splashImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default@2x.png"]] autorelease];
    [self.splashImageView setFrame:[[UIScreen mainScreen] bounds]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
    
    // Set appLaunched to Yes for appirater
    [Appirater appLaunched:YES];
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

-(void)applicationDidEnterBackground: (UIApplication*) application 
{
    // fix W-1237626
    // add the dummy image to the view to prevent sensitive data getting exposed in the app snapshot
    [self.window addSubview:self.splashImageView];
    [super applicationDidEnterBackground : application];
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    [Appirater appEnteredForeground:YES];
}

-(void)applicationDidBecomeActive: (UIApplication*) application 
{
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
    // remove the dummy image from the view
    [self.splashImageView removeFromSuperview];
    [super applicationDidBecomeActive: application];
}

- (void)applicationWillTerminate:(UIApplication *)application 
{
    // Close Localytics Session
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url 
{
    
    // Do something with the url here
    NSString* jsString = [NSString stringWithFormat:@
                          "window.setTimeout(function() { \n"
                          "handleOpenURL(\"%@\"); \n"
                          "},1);", url];
    
    [self.viewController.webView stringByEvaluatingJavaScriptFromString:jsString];
    
    return YES;
}

@end