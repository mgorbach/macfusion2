//
//  MGUtilities.m
//  MacFusion2
//
//  Created by Michael Gorbach on 2/5/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MGUtilities.h"


BOOL isNilOrNull(id object)
{
	if (object == nil || object == [NSNull null])
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

BOOL isNotNilOrNull(id object)
{
	return !(isNilOrNull(object));
}
