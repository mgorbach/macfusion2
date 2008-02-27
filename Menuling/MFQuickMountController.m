//
//  MFQuickMountController.m
//  MacFusion2
//
//  Created by Michael Gorbach on 2/25/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFQuickMountController.h"
#import "MFClient.h"
#import "MFClientFS.h"
#import "MFConstants.h"
#import "MFClientRecent.h"

@implementation MFQuickMountController
- (id)initWithWindowNibName:(NSString*)name
{
	if (self = [super initWithWindowNibName:name])
	{
		client = [MFClient sharedClient];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[[self window] center];
}

- (IBAction)quickMount:(id)sender
{
	NSURL* url = [NSURL URLWithString: [qmTextField stringValue] ];
	if (!url || ![url scheme] || ![url host])
	{
		NSAlert* alert = [NSAlert alertWithMessageText: @"Could not parse URL"
										 defaultButton:@"OK"
									   alternateButton:@""
										   otherButton:@""
							 informativeTextWithFormat:@"Please check the format"];
		[alert setAlertStyle: NSCriticalAlertStyle];
		[alert beginSheetModalForWindow: [self window]
						  modalDelegate: self
						 didEndSelector:nil
							contextInfo:nil];
	}
	else
	{
		NSError* error;
		fs = [[MFClient sharedClient] quickMountFilesystemWithURL:url 
															error:&error];
		if(!fs)
		{
			[self presentError:error 
				modalForWindow:[self window] delegate:nil 
			didPresentSelector:nil 
				   contextInfo:nil];
		}
		else
		{
			// Wait for mount here
			[[NSNotificationCenter defaultCenter]
			 addObserver:self
			 selector:@selector(handleFSNotification:)
			 name:nil
			 object:fs];
			

		}
	}
}

- (IBAction)recentClicked:(id)sender
{
	MFClientRecent* recent = (MFClientRecent*)sender;
	return;
}

- (void)handleFSNotification:(NSNotification*)note
{
	if ([[note name] isEqualToString: kMFClientFSMountedNotification])
	{
		[qmTextField setStringValue: @""];
		[[self window] close];
	}

	if ([[note name] isEqualToString: kMFClientFSFailedNotification])
	{
		if ([fs error])
		{
			[self presentError:[fs error]
				modalForWindow:[self window]
					  delegate:nil
			didPresentSelector:nil
				   contextInfo:nil];
		}
		
		NSAlert* alert = [NSAlert alertWithMessageText:@"Failed to Mount Filesystem"
								   defaultButton:@"OK"
								 alternateButton:@""
									 otherButton:@""
					   informativeTextWithFormat:@"Please try again"];
		[alert setAlertStyle: NSCriticalAlertStyle];
		[alert beginSheetModalForWindow: [self window]
						  modalDelegate:nil 
						 didEndSelector:nil
							contextInfo:nil];
	}
}


@synthesize client;
@end
