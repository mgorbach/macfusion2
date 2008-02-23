//
//  MFPlugin.h
//  macfusiond
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFFSDelegateProtocol.h"

@interface MFPlugin : NSObject {
	NSMutableDictionary* dictionary;
	NSBundle* bundle;
	id <MFFSDelegateProtocol> delegate;
	
}

- (id <MFFSDelegateProtocol>)delegate;
- (id <MFFSDelegateProtocol>)setupDelegate;

@property(readonly) NSDictionary* dictionary;
@property(readonly) NSString* shortName;
@property(readonly) NSString* longName;
@property(readonly) NSBundle* bundle;
@property(readonly) NSString* ID;
@property(readonly) NSString* bundlePath;
@property(readonly) NSString* nibName;



@end
