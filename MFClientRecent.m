//
//  MFClientRecent.m
//  MacFusion2
//
//  Created by Michael Gorbach on 2/25/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFClientRecent.h"
#import "MFConstants.h"

@implementation MFClientRecent
- (id)initWithParameterDictionary:(NSDictionary*)params
{
	if (self = [super init])
	{
		parameters = params;
	}
	
	return self;
}

- (NSDictionary*)parameterDictionary
{
	return parameters;
}

- (NSString*)descriptionString
{
	return [parameters objectForKey: kMFFSDescriptionParameter ];
}

@end
