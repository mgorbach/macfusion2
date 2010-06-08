//
//  MFQuickMountController.m
//  MacFusion2
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "MFQuickMountController.h"
#import "MFClient.h"
#import "MFClientFS.h"
#import "MFConstants.h"
#import "MFClientRecent.h"
#import "MFError.h"

@implementation MFQuickMountController
- (id)initWithWindowNibName:(NSString *)name {
	if (self = [super initWithWindowNibName:name]) {
		_client = [MFClient sharedClient];
	}
	
	return self;
}

- (void)awakeFromNib {
	[[self window] center];
	[recentsTableView setDoubleAction:@selector(recentClicked:)];
	[recentsTableView setTarget:self];
}

- (void)handleMountAttemptForFS:(MFClientFS *)myFS error:(NSError *)error {
	_fs = myFS;
	if(!_fs) {
		[self presentError:error modalForWindow:[self window] delegate:nil didPresentSelector:nil contextInfo:nil];
	} else {
		// Wait for mount here
		[[[recentsTableView window] contentView] addSubview: indicator];
		[_fs setClientFSDelegate:self];
		[indicator setHidden:NO];
		[indicator startAnimation:self];
		[connectButton setHidden:YES];
	}
}

- (IBAction)quickMount:(id)sender {
	if ([[self window] firstResponder] == recentsTableView && [recentsTableView selectedRow] != NSNotFound) {
		[self recentClicked: [[recentsArrayController selectedObjects] objectAtIndex:0]];
		return;
	}
	
	NSURL *url = [NSURL URLWithString:[qmTextField stringValue]];
	if (!url || ![url scheme] || ![url host]) {
		NSAlert *alert = [NSAlert alertWithMessageText: @"Could not parse URL" defaultButton:@"OK" alternateButton:@""otherButton:@"" informativeTextWithFormat:@"Please check the format"];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	} else {
		NSError *error;
		MFClientFS *tempFS = [[MFClient sharedClient] quickMountFilesystemWithURL:url error:&error];
		[self handleMountAttemptForFS:tempFS error:error];
	}
}

- (IBAction)recentClicked:(id)sender {
	MFClientRecent *recent = [[[MFClient sharedClient] recents] objectAtIndex:[recentsTableView selectedRow]];
	NSError *error;
	MFClientFS *tempFS = [_client mountRecent:recent error:&error];
	[self handleMountAttemptForFS:tempFS error:error];
}

- (void)filesystemDidChangeStatus:(MFClientFS *)filesystem {
	if ([_fs isMounted]) {
		[qmTextField setStringValue:@""];
		[indicator stopAnimation:self];
		[indicator setHidden:YES];
		[connectButton setHidden:NO];
		[[self window] close];
	}
		
	if ([_fs isFailedToMount]) {
		if ([_fs error]) {
			[self presentError:[_fs error] modalForWindow:[self window] delegate:self didPresentSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
		}
		
		[indicator stopAnimation:self];
		NSAlert* alert = [NSAlert alertWithMessageText:@"Failed to Mount Filesystem"
								   defaultButton:@"OK"
								 alternateButton:@""
									 otherButton:@""
					   informativeTextWithFormat:@"No error was given"];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:self];
	}
}

- (NSError *)willPresentError:(NSError *)error {
	if ([error code] == kMFErrorCodeMountFaliure || [error code] == kMFErrorCodeNoPluginFound) {
		NSString *detailedDescription = [error localizedDescription];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: @"Could not mount this URL",  NSLocalizedDescriptionKey, detailedDescription, NSLocalizedRecoverySuggestionErrorKey, nil];
		return [NSError errorWithDomain: kMFErrorDomain code:kMFErrorCodeCustomizedFaliure userInfo:userInfo];
	}
	
	return error;
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[indicator stopAnimation:self];
	[indicator setHidden:YES];
	[connectButton setHidden:NO];
}


@synthesize client=_client;
@end
