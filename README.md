## TIXboxLiveEngine

Mac / iOS classes for communication with Xbox LIVE.

## Usage

The TIXboxLiveEngine class is your entry to the wonderful world of Xbox LIVE. It handles all primary connections (getting friends, games, achievements and messages).

### First things first

Before you start trying to sign in, you need to tell the TIXboxLiveEngineCookieStorage where you want to save the cookie information:

    NSString * cacheDirectory = [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/"];
	[[TIXboxLiveEngineCookieStorage sharedCookieStorage] setCookieRootDirectory:cacheDirectory];
	
Also, if you're going to be using the TIXboxLiveEngineImageCache, you'll need to tell that where to save images:

    [[TIXboxLiveEngineImageCache sharedCache] setCacheRootDirectory:cacheDirectory];
    
### Engine setup

Creating an instance is as you'd expect:

    TIXboxLiveEngine * engine = [[TIXboxLiveEngine alloc] init];
    
You can create as many engines as you need (effectively, one engine represents one account).
    
### Signing in / out

    [engine signInWithEmail:@"some email" password:@"some password" callback^(NSError * error){
        if (error){
            // Handle it.
        }
        else
        {
            // You're signed in.
        }
    }];
    
It's also a good idea to set the signOutBlock, which will be called if either the user instigates a sign out (through -signOut) or if the engine detects a session timeout. The block has a BOOL argument which will help you determine the reason:

    [engine setSignOutBlock:^(BOOL userInstigated){
        if (!userInstigated) // Session timeout
    ];
    
I set this when I create the engine instance, but it can be set whenever.

Calling a user instigated sign out is super easy:

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
    
There are similar methods for games, achievements and messages.

## ARC?

Over my dead body

##License

	Copyright (c) 2010 - 2013 Tom Irving. All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY TOM IRVING "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOM IRVING OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.