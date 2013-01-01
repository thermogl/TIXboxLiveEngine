## TIXboxLiveEngine

#### Mac / iOS classes for communication with Xbox LIVE.

## Usage

### First things first

Before you start trying to sign in, you need to tell the TIXboxLiveEngineCookieStorage where you want to save the cookie information (the official API is awful, so we scrape the site).

	NSString * cacheDirectory = [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/"];
	[[TIXboxLiveEngineCookieStorage sharedCookieStorage] setCookieRootDirectory:cacheDirectory];
	
Also, if you're going to be using the TIXboxLiveEngineImageCache, you'll need to tell that where to save images:

	[[TIXboxLiveEngineImageCache sharedCache] setCacheRootDirectory:cacheDirectory];
    
### Engine setup

**The TIXboxLiveEngine class is your entry to the wonderful world of Xbox LIVE. It handles all primary connections (getting friends, games, achievements and messages).**

Creating an instance is as you'd expect:

	TIXboxLiveEngine * engine = [[TIXboxLiveEngine alloc] init];
    
You can create as many engines as you need (effectively, one engine represents one account).
    
### Signing in / out

**Straight forward, just provide an email and password. The engine will encode them correctly.**

	[engine signInWithEmail:@"some email" password:@"some password" callback^(NSError * error){
		if (error){
			// Handle it.
		}
		else
		{
	    	// You're signed in.
		}
	}];
    
**It's also a good idea to set the signOutBlock**. This will be called if either the user instigates a sign out (through -signOut) or if the engine detects a session timeout. The block has a BOOL argument which will help you determine the reason:

	[engine setSignOutBlock:^(BOOL userInstigated){
		if (!userInstigated) // Session timeout
	}];
    
I set this when I create the engine instance, but it can be set whenever.

**Calling a user instigated sign out is super easy:**

	[engine signOut];
    
This'll take care of cancelling any running connections, removing cookie information and, if the signOutBlock is set, call the block with the userInstigated argument set to YES.

### I'm signed in, now what?

Now you can start interacting with various elements of Xbox LIVE. The first thing Friendz does when signed in is to download the friends, games and messages lists.

Simple stuff:

	[engine getFriendsWithCallback:^(NSError * error, NSArray * friends, NSInteger onlineCount){
		if (!error){
			// 'friends' contains TIXboxLiveFriend objects
		}
	}];
    
**There are similar methods for games, achievements and messages.**

### User info

You can access the engine's TIXboxLiveUser through the 'user' property. **The user represents the profile of the account you signed in with**. You can see from the header it gives you access to the players real name, location, motto, bio, etc.

It also a method for changing this information:

	[user changeGamerProfileName:@"Name" motto:@"Motto" location:@"Location" bio:@"Bio" callback:^(NSError * error){
		if (error) // Handle it
	}];
    
### Friends

There is a method for downloading profile information (real name, motto, location, bio, etc) in the TIXboxLiveFriend class.

	[friend getGamerInfoWithCallback:^(NSError *error, NSString *name, NSString *motto, NSString *location, NSString *bio, NSString *gamerscore, NSString *info){
		// Display the information.
	}];
	
You can send friend requests from the engine with:

	[engine sendFriendRequestToGamer:@"Some Gamertag" callback:^(NSError *error, NSString *gamertag) {
		if (error) // Handle error
	}];
	
### Messages

To get the actual message body, and if there's an image attachment, you call a method in the TIXboxLiveMessage class.

	[message getMessageWithBodyCallback:^(NSString * body){ 
		// Display the message 
	} imageCallback:^(UIImage * image){ 
		// Display the image				
	}];
	
Sending messages, like friend requests, is done on the TIXboxLiveEngine.

	[engine sendMessage:@"Some message" recipients:[@"Gamertag", @"Gamertag 2"] callback:^(NSError * error, NSArray * recipients){
		if (error) // Handle error
	}];

### Tiles

Friends, Games and Achievements all have tiles associated with them, and the URLs for these tiles can be found as tileURL properties on the classes. The TIXboxLiveEngineImageCache is the primary method for downloading the tiles, though you can use your own classes if that's easier.

The following code is taken from the FriendsCell.m used in Friendz on iOS:

    BOOL local = [[TIXboxLiveEngineImageCache sharedCache] getImageForURL:friend.tileURL completion:^(UIImage *image, NSURL * URL){
		if ([URL isEqual:friend.tileURL]){
			[self setGamertile:[image roundCornerImageWithCornerRadius:5]];
			[self setNeedsDisplay];
		}
	}];
	if (!local) [self setGamertile:[[UIImage imageNamed:@"avatar-tile"] roundCornerImageWithCornerRadius:5]];
	
The return value of -getImageForURL:completion: indicates if the image is on disk, or needs to be downloaded. I use this in Friendz to decide if a placeholder is needed whilst the download completes.

**TIXboxLiveEngineImageCache will take care of cropping game box art to square images.**

### Cross Platform Compatibility

**The TIXboxLiveEngine is built to run on both Mac and iOS. Anywhere you see UIImage in the above code samples, NSImage can be used in its place on Mac.**

### Min OS requirements

iOS 5.

OS X 10.7

### Stuff I've missed

The engine does more than is mentioned here, but should be pretty self explanatory if you look at the header files. **Any questions can be directed to me on Twitter ([@thermogl](http://twitter.com/thermogl)).**

## ARC?

Over my dead body.

##License

	Copyright (c) 2010 - 2013 Tom Irving. All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY TOM IRVING "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOM IRVING OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.