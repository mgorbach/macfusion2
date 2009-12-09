/*
 *  MFFSDelegate.h
 *  MacFusion2
 */

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@protocol MFFSDelegateProtocol <NSObject>

// Task arguments
- (NSArray *)taskArgumentsForParameters:(NSDictionary *)parameters;

// Parameters
- (NSArray *)parameterList;
- (NSDictionary *)defaultParameterDictionary;

- (id)impliedValueParameterNamed:(NSString*)name otherParameters:(NSDictionary*)parameters;
- (NSString *)descriptionForParameters:(NSDictionary *)parameters;

// Validation
- (BOOL)validateValue:(id)value forParameterName:(NSString*)paramName error:(NSError**)error;

- (BOOL)validateParameters:(NSDictionary *)parameters error:(NSError **)error;


// Plugin Wide Stuff
- (NSString *)executablePath;
- (NSArray *)urlSchemesHandled;

// UI
- (NSArray *)viewControllerKeys;
- (NSViewController *)viewControllerForKey:(NSString *)key;
 
@optional
- (NSDictionary *)taskEnvironmentForParameters:(NSDictionary *)parameters;
- (NSDictionary *)parameterDictionaryForURL:(NSURL *)url error:(NSError**)error;
- (NSError *)errorForParameters:(NSDictionary *)parameters output:(NSString*)output;

// Security
- (NSArray *)secretsList;
- (NSArray *)secretsClientsList;

// Subclassing
- (Class)subclassForClass:(Class)superclass;

@end