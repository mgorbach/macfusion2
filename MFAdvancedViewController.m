//
//  MFAdvancedViewController.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/20/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFAdvancedViewController.h"
#import "MFClientFS.h"

@implementation MFAdvancedViewController
- (void)awakeFromNib {
	[iconView bind:@"fs" toObject:self withKeyPath:@"representedObject" options:nil];
}

- (IBAction)chooseIcon:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:NO];
	[panel setAllowedFileTypes:[NSArray arrayWithObject: @"icns"]];
	NSInteger returnValue = [panel runModal];
	if (returnValue == NSOKButton && [[panel URLs] count] > 0) {
		NSString *filename = [[[panel URLs] objectAtIndex:0] path];
		NSImage *iconImage = [[NSImage alloc] initWithContentsOfFile:filename];
		if (iconImage) {
			[(MFClientFS*)[self representedObject] setIconImage:iconImage];
		}
	}
}

@end
