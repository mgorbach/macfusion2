//
//  MFClientFSUI.h
//  MacFusion2
//
//  Created by Michael Gorbach on 3/30/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFClientFS.h"

// UI Keys
extern NSString* kMFUIMainViewKey;
extern NSString* kMFUIAdvancedViewKey;
extern NSString* kMFUIMacfusionAdvancedViewKey;

@interface MFClientFS (MFClientFSUI)

- (NSArray*)configurationViewControllers;
- (NSView*)editingView;
- (NSView*)addTopViewToView:(NSView*)originalView;

@end
