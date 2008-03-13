//
//  new_ssh_askpass.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#import "MFSecurity.h"
#import "MFClientFS.h"
#import "MFLoggingController.h"
#import "MFNetworkFS.h"
#define self @"SSHFS_ASKPASS"
#define NO_LOG_STDOUT

int main(int argc, char *argv[])
{
	[[MFLoggingController sharedController] setPrintToStandardOut: NO];
	NSString* token = [[[NSProcessInfo processInfo] environment] objectForKey: @"SSHFS_TOKEN"];
	NSString* password;
	
	if (!token)
	{
		// MFLogS(self, @"Could not find token");
		return -1;
	}
	else
	{
		MFClientFS* fs = (MFClientFS*)getFilesystemForToken( token );
		if (!fs)
		{
			// MFLogS(self, @"Could not get fs for token"); 
			return -1;
		}
		
		NSDictionary* secrets = getSecretsDictionaryForFilesystem( fs );
		if (!secrets)
		{
			// MFLogS(self, @"Could not get secrets for token. Querying.");
			password = queryForFSNetworkPassword( fs );
			// MFLogS(self, @"Query result %@", password);
			
		}
		else
		{
			password = [secrets objectForKey: kNetFSPasswordParameter];
		}
		
		if (password)
		{
			// MFLogS(self, @"Password confirmed from secrets: %@", password);
		}
		else
		{
			// MFLogS(self, @"Token secrets found, but no password. Querying.");
			password = queryForFSNetworkPassword( fs );
			// MFLogS(self, @"Query result %@", password);
		}
		
		printf("%s", [password UTF8String]);
	}
	
	return 0;
}

