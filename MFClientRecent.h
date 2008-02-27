//
//  MFClientRecent.h
//  MacFusion2
//
//  Created by Michael Gorbach on 2/25/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MFClientRecent : NSObject {
	NSDictionary* parameters;
}

- (id)initWithParameterDictionary:(NSDictionary*)params;

@property(readonly, retain) NSDictionary* parameterDictionary;
@property(readonly) NSString* descriptionString;

@end
