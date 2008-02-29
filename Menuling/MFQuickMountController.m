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
#import "MFError.h"

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
//	[[[self window] contentView] setWantsLayer: YES];
	[qmTabView selectTabViewItemAtIndex: 0];
}

- (void)handleMountAttemptForFS:(MFClientFS*)myFS
						  error:(NSError*)error
{
	fs = myFS;
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
//		[qmTabView selectTabViewItemAtIndex: 1];
		[qmTabView setNeedsDisplay:YES];
		[qmProgress startAnimation:self];
	}
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
		MFClientFS* tempFS = [[MFClient sharedClient] quickMountFilesystemWithURL:url 
															error:&error];
		[self handleMountAttemptForFS:tempFS error:error];
	}
}

- (IBAction)recentClicked:(id)sender
{
	MFClientRecent* recent = (MFClientRecent*)sender;
	NSError* error;
	MFClientFS* tempFS = [client mountRecent: recent error:&error];
	[self handleMountAttemptForFS: tempFS error:error];
}

- (void)handleFSNotification:(NSNotification*)note
{
	if ([[note name] isEqualToString: kMFClientFSMountedNotification])
	{
		[qmTextField setStringValue: @""];
		[qmTabView selectTabViewItemAtIndex:0];
		[qmProgress stopAnimation:self];
		[[self window] close];
	}

	if ([[note name] isEqualToString: kMFClientFSFailedNotification])
	{
		if ([fs error])
		{
			[self presentError:[fs error]
				modalForWindow:[self window]
					  delegate:self
			didPresentSelector:@selector(alertDidEnd:returnCode:contextInfo:)
				   contextInfo:nil];
		}
		
		NSAlert* alert = [NSAlert alertWithMessageText:@"Failed to Mount Filesystem"
								   defaultButton:@"OK"
								 alternateButton:@""
									 otherButton:@""
					   informativeTextWithFormat:@"Please try again"];
		[alert setAlertStyle: NSCriticalAlertStyle];
		[alert beginSheetModalForWindow:[self window]
						  modalDelegate:self 
						 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
							contextInfo:self];
		[qmProgress stopAnimation:self];
	}
}

- (NSError*)willPresentError:(NSError*)error
{
	if ([error code] == kMFErrorCodeMountFaliure ||
		[error code] == kMFErrorCodeNoPluginFound)
	{
		NSString* description = [NSString stringWithFormat:
								 @"Could not mount this URL: %@",
								 [error localizedDescription]];
		return [MFError errorWithErrorCode:kMFErrorCodeMountFaliure
							   description:description];
	}
	
	return error;
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[qmTabView selectTabViewItemAtIndex: 0];
}


@synthesize client;
@end
