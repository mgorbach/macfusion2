//
//  MFClientFSUI.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/30/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFClientFSUI.h"
#import "MFAdvancedViewController.h"
#import "MGTransitioningTabView.h"
#import "MGTestView.h"

NSString* kMFUIMainViewKey=@"main";
NSString* kMFUIAdvancedViewKey=@"advanced";
NSString* kMFUIMacfusionAdvancedViewKey=@"macfusion";

@implementation MFClientFS (MFClientFSUI)

- (NSViewController*)viewControllerForKey:(NSString*)key
{
	NSViewController* delegateViewController = [delegate viewControllerForKey: key];
	if (!delegateViewController || ![delegateViewController isKindOfClass: [NSViewController class]])
	{
		// MFLogS(self, @"Delegate returns no or bad view controller for key %@", key);
	}
	if (delegateViewController && ![delegateViewController view])
	{
		MFLogS(self, @"View from delegate has no view associated!");
	}
	
	if (delegateViewController)
		return delegateViewController;
	
	// Macfusion's own keys
	if (key == kMFUIMacfusionAdvancedViewKey)
	{
		NSViewController* macfusionAdvancedController = [[MFAdvancedViewController alloc] 
														 initWithNibName: @"macfusionAdvancedView"
														 bundle: [NSBundle bundleForClass: [self class]]];
		[macfusionAdvancedController setTitle: @"Macfusion"];
		return macfusionAdvancedController;
	}
	
	return nil;
}

- (NSArray*)configurationViewControllers
{
	if (!viewControllers)
	{
		NSArray* configurationViewControllerKeys = [delegate viewControllerKeys];
		NSMutableArray* configurationViewControllers = [NSMutableArray array];
		
		if (!configurationViewControllerKeys  || [configurationViewControllerKeys count] == 0)
		{
			MFLogS(self, @"Delegate specifies no configuration view controllers!");
			return nil;
		}
		
		for(NSString* key in configurationViewControllerKeys)
		{
			NSViewController* delegateViewController = [self viewControllerForKey: key];
			if (delegateViewController)
				[configurationViewControllers addObject: delegateViewController];
		}
		
		[configurationViewControllers  makeObjectsPerformSelector:@selector(setRepresentedObject:)
													   withObject:self];
		viewControllers = [configurationViewControllers copy];
	}
	
	return viewControllers;
}

- (NSView*)addTopViewToView:(NSView*)originalView 
{
	if (!topViewController)
	{
		NSBundle* bundle = [NSBundle bundleForClass: [MFClientFS class]];
		topViewController = [[NSViewController alloc] initWithNibName: @"topView" bundle: bundle];
		[topViewController setRepresentedObject: self];
	}

	NSRect nameViewFrame = [[topViewController view] frame];
	NSRect originalViewFrame = [originalView frame];
	
	NSSize newViewSize = NSMakeSize( originalViewFrame.size.width, originalViewFrame.size.height + nameViewFrame.size.height);
	NSView* newView = [NSView new];
	[newView setFrameOrigin: NSMakePoint(0, 0)];
	[newView setFrameSize: newViewSize];
	[newView addSubview: [topViewController view]];
	[newView addSubview: originalView];
	[[topViewController view] setFrameOrigin: NSMakePoint( 0,  originalViewFrame.size.height)];
	[newView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
	return newView;
}

- (NSView*)editingView
{
	NSArray* configurationViewControllers = [self configurationViewControllers];
	
	if (!editingTabView)
	{
		NSTabView* tabView = [MGTransitioningTabView new];
		[tabView setFont: [NSFont systemFontOfSize: 
						   [NSFont systemFontSizeForControlSize: NSSmallControlSize]]];
		[tabView setControlSize: NSSmallControlSize];
		
		float view_width = 300;
		float tabview_x = 20;
		float tabview_y = 38;
		
		if (configurationViewControllers && [configurationViewControllers count] > 0)
		{
			for(NSViewController* viewController in configurationViewControllers)
			{
				NSTabViewItem* tabViewItem = [NSTabViewItem new];
				[tabViewItem setLabel: [viewController title] ? [viewController title] : @"No title"];
				[tabViewItem setView: [viewController view]];
				[tabView addTabViewItem: tabViewItem];
			}
		
			[tabView setFrame: NSMakeRect( 0, 0, tabview_x+view_width, tabview_y+150 )];
			editingTabView = tabView;
		}
		else
		{
			MFLogSO(self, @"No view loaded for fs %@", self);
			return nil;
		}
	}
	
	return editingTabView;

}

@end
