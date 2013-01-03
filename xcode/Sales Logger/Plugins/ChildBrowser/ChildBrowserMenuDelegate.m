//
//  ChildBrowserMenuDelegate.m
//  touch
//
//  Created by Alicia Ong on 4/17/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import "ChildBrowserMenuDelegate.h"

@implementation ChildBrowserMenuDelegate

@synthesize documentBtn;

- (id) initWithButton: (UIBarButtonItem *) button{
    self = [super init];
    documentBtn = button;
    return self;
}

- (void) documentInteractionControllerWillPresentOpenInMenu: (UIDocumentInteractionController*) controller{
    //disable menu button
    [documentBtn setEnabled:NO];
    
}

/**
 * Clicking on other area on the screen will call this method to dismiss the menu but not called 
 * when selecting one of the native apps in the menu.
 */
- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController*) controller{
    //reenable menu button
    [documentBtn setEnabled:YES];
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
    //reenable menu button
    [documentBtn setEnabled:YES];
}

@end
