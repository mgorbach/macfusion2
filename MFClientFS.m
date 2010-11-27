//
//  MFClientFS.m
//  MacFusion2
//
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

#import "MFClientFS.h"
#import "MFConstants.h"
#import "MFClientPlugin.h"
#import "MFServerFSProtocol.h"
#import "MFSecurity.h"
#import "IconFamily.h"
#import "MFAdvancedViewController.h"
#import "MGNSImage.h"
#import "MFLogging.h"

#import <QuartzCore/QuartzCore.h>

@interface MFClientFS (PrivateAPI)
- (void)fillInitialData;
- (void)registerNotifications;
- (void)copyParameters;
- (void)copyStatusInfo;
@end

@implementation MFClientFS

+ (MFClientFS*)clientFSWithRemoteFS:(id)remoteFS clientPlugin:(MFClientPlugin *)plugin {
	MFClientFS *fs = nil;
	Class FSClass = [plugin subclassForClass: self];
	
	fs = [[FSClass alloc] initWithRemoteFS: remoteFS clientPlugin: plugin];
	return fs;
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	if ([key isEqualToString: @"displayDictionary"] || [key isEqualToString: @"imagePath"]) {
		return [NSSet setWithObjects:KMFStatusDict, kMFParameterDict, nil];	
	} else {
		return [super keyPathsForValuesAffectingValueForKey: key];
	}
}

- (id)initWithRemoteFS:(id)remoteFS clientPlugin:(MFClientPlugin *)p {
	self = [super init];
	if (self != nil) {
		remoteFilesystem = remoteFS;
		[remoteFS setProtocolForProxy:@protocol(MFServerFSProtocol)];
		plugin = p;
		delegate = [plugin delegate];
		[self fillInitialData];
		[self registerNotifications];
		displayOrder = 9999;
		[self updateSecrets];
	}
	
	return self;
}


- (void)registerNotifications {
}

- (void)copyStatusInfo {
	[self willChangeValueForKey:KMFStatusDict];
	statusInfo = [[remoteFilesystem statusInfo] mutableCopy];
	NSAssert(![statusInfo isProxy], @"Status Info from DO is a Proxy. Oh shit.");
	[self didChangeValueForKey:KMFStatusDict];
}

- (void)copyParameters {
	[self willChangeValueForKey:kMFParameterDict];
	parameters = [[remoteFilesystem parameters] mutableCopy];
	NSAssert(![parameters isProxy], @"Parameters from DO is a Proxy. Oh shit.");
	[self didChangeValueForKey:kMFParameterDict];
}

- (void)fillInitialData {
	[self copyStatusInfo];
	[self copyParameters];
}

#pragma mark Notifications To Clients
- (void)sendNotificationForStatusChangeFrom:(NSString *)previousStatus to:(NSString *)newStatus
{
	// NSLog(@"Sending notification: Previous %@ New %@", previousStatus, newStatus);
	if ([previousStatus isEqualToString: newStatus]) {
		// Send No Notification
	} else {
		if (clientFSDelegate && [clientFSDelegate respondsToSelector:@selector(filesystemDidChangeStatus:)]) {
			[clientFSDelegate filesystemDidChangeStatus:self];
		}
	}
		
}

#pragma mark Synchronization across IPC
- (void)noteStatusInfoChanged {
	NSString *previousStatus = self.status;
	[self copyStatusInfo];
	[self sendNotificationForStatusChangeFrom:previousStatus to:self.status];
}

- (void)noteParametersChanged {
	[self copyParameters];
}

- (NSDictionary *)displayDictionary {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict addEntriesFromDictionary: parameters];
	[dict addEntriesFromDictionary: statusInfo];
	return [dict copy];
}

# pragma mark Action Methods
- (void)mount {
	[remoteFilesystem mount];
}

- (void)unmount {
	[remoteFilesystem unmount];
}


#pragma mark Editing
- (void)setParameters:(NSMutableDictionary *)p {
	parameters = p;
}

- (void)beginEditing {
	isEditing = YES;
	backupParameters = [NSDictionary dictionaryWithDictionary:[self parameters]];
	backupSecrets = [NSDictionary dictionaryWithDictionary:secrets];
}

- (NSError *)endEditingAndCommitChanges:(BOOL)commit {
	[viewControllers makeObjectsPerformSelector: @selector(commitEditing)];
	[topViewController commitEditing];
	
	if (!isEditing) {
		[[NSException exceptionWithName:kMFBadAPIUsageException reason:@"Calling endEditing without previous call to beginEditing"
							   userInfo:nil] raise];
	}
	
	if (commit) {
		NSError *result = nil;
		if (![backupParameters isEqualToDictionary: parameters]) {
			result = [remoteFilesystem validateAndSetParameters: parameters];
		}
		if (result) {
			// Validation failed
			return result;
		} else {
			// Update secure information
			if (![secrets isEqualToDictionary: backupSecrets]) {
				mfsecSetSecretsDictionaryForFilesystem( secrets, self );
			}
			isEditing = NO;
			viewControllers = nil;
			topViewController = nil;
			editingTabView = nil;
			return nil;
		}
	} else {
		isEditing = NO;
		[self setParameters: [backupParameters mutableCopy] ];
		[self setSecrets: [backupSecrets mutableCopy]];
		viewControllers = nil;
		topViewController = nil;
		editingTabView = nil;
	}
	
	return nil;
}

- (BOOL)canDoEditing {
	return ([self isUnmounted] || [self isFailedToMount]);
}

- (NSImage *)iconImage {
	return [[NSImage alloc] initWithContentsOfFile:self.iconPath];
}

- (NSColor *)tintColor {
	MFClientFS *fs = self;
	if ([fs isMounted]) {
		return [NSColor greenColor];
	}
	if ([fs isFailedToMount]) {
		return [NSColor redColor];
	}
	if ([fs isWaiting]) {
		return [NSColor yellowColor];
	}
	if ([fs isUnmounted]) {
		return [NSColor grayColor];
	}
	
	return nil;
}

static CGColorRef CGColorCreateFromNSColor(CGColorSpaceRef  colorSpace, NSColor *color) {
	NSColor *deviceColor = [color colorUsingColorSpaceName:  
							NSDeviceRGBColorSpace];
	
	CGFloat components[4];
	[deviceColor getRed: &components[0] green: &components[1] blue:&components[2] alpha:&components[3]];
	
	return CGColorCreate (colorSpace, components);
}

// TODO: Cache this image instead of regenerating. Don't think this affects performance much right now.
- (NSImage*)coloredImage {
	CGFloat tint_alpha = 0.3;
	
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL( (CFURLRef)[NSURL fileURLWithPath: self.imagePath], NULL );
	CGImageRef cgImageOriginalRep = CGImageSourceCreateImageAtIndex( imageSource, 0, NULL );
	NSSize oldSize = NSMakeSize( CGImageGetWidth(cgImageOriginalRep), CGImageGetHeight(cgImageOriginalRep) );
	CGRect fullContext = CGRectMake( 0, 0, oldSize.width, oldSize.height );
	CGContextRef context = CGBitmapContextCreate( NULL, oldSize.width, oldSize.height, 
												 CGImageGetBitsPerComponent( cgImageOriginalRep ),
												 CGImageGetBytesPerRow( cgImageOriginalRep ),
												 CGImageGetColorSpace( cgImageOriginalRep ),
												 kCGImageAlphaPremultipliedLast );
	
	CGContextSetInterpolationQuality( context, kCGInterpolationHigh );
	
	CGContextDrawImage( context, fullContext, cgImageOriginalRep );
	CGContextClipToMask( context, fullContext, cgImageOriginalRep );
	CGContextSetBlendMode( context, kCGBlendModeColor ) ;
	CGColorRef tintColor = CGColorCreateFromNSColor( CGBitmapContextGetColorSpace( context ), 
													[[self tintColor] colorWithAlphaComponent: tint_alpha ] );
	CGContextSetFillColorWithColor( context , tintColor );
	CGContextFillRect( context, fullContext );
	CGImageRef newCGImage = CGBitmapContextCreateImage( context );
	
	NSBitmapImageRep *newImageRep = [[NSBitmapImageRep alloc] initWithCGImage: newCGImage ];
	NSImage *newImage = [[NSImage alloc] initWithSize: oldSize];
	[newImage addRepresentation: newImageRep];
	
	CGColorRelease( tintColor );
	CGImageRelease( cgImageOriginalRep );
	CGImageRelease( newCGImage );
	CGContextRelease( context );
	CFRelease( imageSource );
	
	return newImage;
}

- (void)setPauseTimeout:(BOOL)p {
	[remoteFilesystem setPauseTimeout:p];
}

# pragma mark UI
- (void)setIconImage:(NSImage *)image {
	if (image == nil) {
		[self willChangeValueForKey:@"parameters"];
		[parameters removeObjectForKey: kMFFSVolumeIconPathParameter];
		[parameters removeObjectForKey: kMFFSVolumeImagePathParameter];
		[self didChangeValueForKey:@"parameters"];
		return;
	}

	BOOL isDir;
	NSString* iconDirPath = [@"~/Library/Application Support/Macfusion/Icons" stringByExpandingTildeInPath];
	
	// Make Icons Directory if needed
	if (![[NSFileManager defaultManager] fileExistsAtPath:iconDirPath isDirectory:&isDir] || !isDir)
	{
		NSError* dirCreateError;
		BOOL ok = [[NSFileManager defaultManager] createDirectoryAtPath:iconDirPath
								  withIntermediateDirectories:YES
												   attributes:nil 
														error:&dirCreateError];
		if (!ok) {
			MFLogS(self, @"Directory create for icon storage failed. Error %@", dirCreateError);
			return;
		}
	}
	
	// Write Icon
	NSString* fullIconPath = [iconDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.icns", self.uuid]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:fullIconPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:fullIconPath error:NULL];
	}
		
	
	IconFamily *icon = [[IconFamily alloc] initWithThumbnailsOfImage:image];
	BOOL writeOK = [icon writeToFile:fullIconPath];
	if (!writeOK) {
		MFLogS(self, @"Failed to write to file icon %@", icon);
		return;
	}

	// Write Black and White image
	NSString *fullBWImagePath = [iconDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.tiff", self.uuid]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:fullBWImagePath]) {
		[[NSFileManager defaultManager] removeItemAtPath:fullBWImagePath error:nil];
	}
	
	CIFilter *bwFilter = [CIFilter filterWithName:@"CIColorControls"];
	[bwFilter setDefaults];
	[bwFilter setValue: [image ciImageRepresentation] forKey: @"inputImage"];
	[bwFilter setValue: [NSNumber numberWithFloat:0.0] forKey: @"inputSaturation"];
	CIImage *bwCIImage = [bwFilter valueForKey:@"outputImage"];
	
	NSData *tiffData = [[bwCIImage nsImageRepresentation] TIFFRepresentation];
	writeOK = [tiffData writeToFile:fullBWImagePath atomically:YES];
	if (!writeOK) {
		MFLogS(self, @"Failed to write BW tiff file at path %@", fullBWImagePath);
		return;
	}
	
	// Set the data and cause updates
	[self willChangeValueForKey:@"parameters"];
	[parameters setObject:fullIconPath forKey:kMFFSVolumeIconPathParameter];
	[parameters setObject:fullBWImagePath forKey:kMFFSVolumeImagePathParameter]; 
	[self didChangeValueForKey:@"parameters"];
}

@synthesize displayOrder, clientFSDelegate;
@end
