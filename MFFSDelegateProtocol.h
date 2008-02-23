/*
 *  MFServerProtocol.h
 *  MacFusion2
 *
 *  Created by Michael Gorbach on 1/31/08.
 *  Copyright 2008 Michael Gorbach. All rights reserved.
 *
 */

@protocol MFFSDelegateProtocol <NSObject>


- (NSArray*)taskArgumentsForParameters:(NSDictionary*)parameters;

- (NSArray*)parameterList;
- (NSDictionary*)defaultParameterDictionary;

- (id)impliedValueParameterNamed:(NSString*)name 
				 otherParameters:(NSDictionary*)parameters;

- (BOOL)validateValue:(id)value 
	 forParameterName:(NSString*)paramName 
				error:(NSError**)error;

- (BOOL)validateParameters:(NSDictionary*)parameters
					 error:(NSError**)error;

- (NSString*)descriptionForParameters:(NSDictionary*)parameters;

- (NSString*)executablePath;
 
@optional
- (NSDictionary*)taskEnvironmentForParameters:(NSDictionary*)parameters;

@end