//
//  MFPreferencePane.m
//  MacFusion2
//
//  Created by Michael Gorbach on 12/8/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFPreferencePane.h"
#import "MFConstants.h"
#import "MFClient.h"
#import "MFClientFS.h"

@interface MFPreferencePane(PrivateAPI)
- (BOOL)establishCommunication;
@end

@implementation MFPreferencePane
- (id)initWithBundle:(NSBundle*)bundle
{
	if ( ( self = [super initWithBundle:bundle] ) != nil )
	{
		// Do stuff
	}
	
	return self;
}


- (void)setUIForFaliure
{
	
}

- (void)mainViewDidLoad
{
	/*
	MFClient* client = [MFClient sharedClient];
	if (! [client establishCommunication])
	{
		[self setUIForFaliure];
	}
	else
	{
		[client fillInitialStatus];
		NSDictionary* filesystems = [client filesystems];
		[filesystemDictionaryController setContent: filesystems];
	}
	 */
}

-(void)tableViewSelectionDidChange:(NSNotification*)note
{
	/*
	NSLog(@"Changed and received %@", note);
	if ([filesystemDictionaryController selectionIndex] != NSNotFound)
	{
		MFClientFS* fs = [[filesystemDictionaryController selectedObjects] objectAtIndex: 0];
		
		NSString* nibName = [[fs plugin] nibName];
		NSString* bundlePath = [[fs plugin] bundlePath];
		
		NSMutableArray* objs = [NSMutableArray array];
		NSDictionary* nameTable = [NSDictionary dictionaryWithObjectsAndKeys: 
								   self, NSNibOwner,
								   objs, NSNibTopLevelObjects, nil];
		if (! [[NSBundle bundleWithPath:bundlePath] loadNibFile:nibName
											  externalNameTable:nameTable
													   withZone:NSDefaultMallocZone()])
		{
			NSLog(@"Failed to load nib! %@, %@, %@", fs, nibName, bundlePath);
		}
		else
		{
			NSLog(@"Nib load OK %@ %@", nibName, bundlePath);
			NSLog(@"%@", configurationView);
			[confViewBox setContentView: configurationView];
			[filesystemObjectController setContent: fs];
		}
	}
	else // No selection
	{
		[confViewBox setContentView: nil];
		[filesystemObjectController setContent: nil];
	}
	 */
}

- (void)willSelect
{
	
}

@end
