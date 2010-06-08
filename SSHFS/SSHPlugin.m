//
//  SSHPlugin.m
//  MacFusion2
//
//  Created by Michael Gorbach on 11/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SSHPlugin.h"

@implementation SSHPlugin
- (NSDictionary*)defaultParameterDictionary
{
	NSMutableDictionary* defaults = [NSMutableDictionary
									 dictionaryWithCapacity:10];
//	[defaults setObject:@"Unnamed"
//				 forKey:@"name"];
//	[defaults setObject: [NSNull null]
//				 forKey:@"Host"];
	[defaults setObject: [NSNumber numberWithInt:22]
				 forKey:@"Port"];
	[defaults setObject: NSUserName()
				 forKey:@"User"];
	[defaults setObject: @""
				 forKey:@"Directory"];
	return [defaults copy];
}

@end
