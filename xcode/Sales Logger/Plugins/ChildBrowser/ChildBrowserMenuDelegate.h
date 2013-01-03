//
//  ChildBrowserMenuControllerDelegate.h
//  touch
//
//  Created by Alicia Ong on 4/16/12.
//  Copyright (c) 2012 Salesforce.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChildBrowserViewController.h"

@interface ChildBrowserMenuDelegate : NSObject<UIDocumentInteractionControllerDelegate>


@property (assign) UIBarButtonItem* documentBtn;

- (id) initWithButton: (UIBarButtonItem*) button;
- (void) documentInteractionControllerWillPresentOpenInMenu: (UIDocumentInteractionController*) controller;
- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController*) controller;

@end