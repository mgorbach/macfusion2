//
//  MFError.h
//  MacFusion2
//
//  Created by Michael Gorbach on 2/14/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MFError : NSError {

}

+ (MFError*)parameterMissingErrorWithParameterName:(NSString*)parameter;

+ (MFError*)invalidParameterValueErrorWithParameterName:(NSString*)parameter
												  value:(id)value
											description:(NSString*)description;

@end
