/*
 *  MFFSDelegate.h
 *  MacFusion2
 *
 *  Created by Michael Gorbach on 1/31/08.
 *  Copyright 2008 Michael Gorbach. All rights reserved.
 *
 */

@protocol MFFSDelegateProtocol <NSObject>

// Task arguments
- (NSArray*)taskArgumentsForParameters:(NSDictionary*)parameters;

// Parameters
- (NSArray*)parameterList;
- (NSDictionary*)defaultParameterDictionary;

- (id)impliedValueParameterNamed:(NSString*)name 
				 otherParameters:(NSDictionary*)parameters;
- (NSString*)descriptionForParameters:(NSDictionary*)parameters;

// Validation
- (BOOL)validateValue:(id)value 
	 forParameterName:(NSString*)paramName 
				error:(NSError**)error;

- (BOOL)validateParameters:(NSDictionary*)parameters
					 error:(NSError**)error;


// Plugin Wide Stuff
- (NSString*)executablePath;
- (NSArray*)urlSchemesHandled;

// UI
- (NSDictionary*)configurationViewControllers;
 
@optional
- (NSDictionary*)taskEnvironmentForParameters:(NSDictionary*)parameters;
- (NSDictionary*)parameterDictionaryForURL:(NSURL*)url
									 error:(NSError**)error;
- (NSError*)errorForParameters:(NSDictionary*)parameters 
						output:(NSString*)output;

// Security
- (NSArray*)secretsList;
- (NSArray*)secretsClientsList;
@end