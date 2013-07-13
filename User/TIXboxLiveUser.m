//
//  TIXboxLiveUser.m
//  Friendz
//
//  Created by Tom Irving on 03/01/2011.
//  Copyright 2011 Tom Irving. All rights reserved.
//

#import "TIXboxLiveUser.h"
#import "TIURLRequestParameter.h"
#import "TIXboxLiveEngineAdditions.h"
#import "TIXboxLiveEngineConnection.h"
#import "TIXboxLiveFriend.h"
#import "TIXboxLiveMessage.h"

NSString * const TIXboxLiveUserDidReceiveGamerProfileNotificationName = @"TIXboxLiveUserDidReceiveGamerProfileNotificationName";
NSString * const TIXboxLiveUserDidFinishChangingGamerProfileNotificationName = @"TIXboxLiveUserDidFinishChangingGamerProfileNotificationName";

@interface TIXboxLiveUser (Private)
- (TIXboxLiveEngineConnection *)connectionWithRequest:(NSMutableURLRequest *)request type:(TIXboxLiveEngineConnectionType)type;
- (void)downloadTileFromURL:(NSURL *)tileURL;
- (void)doCallbackForProfileChangeSuccessfully:(BOOL)successfully connection:(TIXboxLiveEngineConnection *)connection;
- (void)doCallbackForProfileReceived:(TIXboxLiveEngineConnection *)connection;
- (void)setOldValues;
- (void)clearOldValues;
@end

@implementation TIXboxLiveUser {
	
	NSString * _oldName;
	NSString * _oldMotto;
	NSString * _oldLocation;
	NSString * _oldBio;
	
	NSMutableDictionary * _returnDataDict;
}
@synthesize gamertag = _gamertag;
@synthesize gamerscore = _gamerscore;
@synthesize realName = _realName;
@synthesize motto = _motto;
@synthesize location = _location;
@synthesize bio = _bio;
@synthesize tileURL = _tileURL;

- (id)init {
	
	if ((self = [super init])){
		
		_oldName = nil;
		_oldMotto = nil;
		_oldLocation = nil;
		_oldBio = nil;
		_returnDataDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (id)initWithGamertag:(NSString *)aTag gamerscore:(NSString *)aScore tileURL:(NSURL *)aURL {
	
	if ((self = [self init])){
		_gamertag = [aTag copy];
		_gamerscore = [aScore copy];
		_tileURL = aURL;
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [self init])){
		
		_gamertag = [[aDecoder decodeObjectForKey:@"Gamertag"] copy];
		_gamerscore = [[aDecoder decodeObjectForKey:@"Gamerscore"] copy];
		_realName = [[aDecoder decodeObjectForKey:@"RealName"] copy];
		_motto = [[aDecoder decodeObjectForKey:@"Motto"] copy];
		_location = [[aDecoder decodeObjectForKey:@"Location"] copy];
		_bio = [[aDecoder decodeObjectForKey:@"Bio"] copy];
		_tileURL = [[aDecoder decodeObjectForKey:@"TileURL"] copy];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:_gamertag forKey:@"Gamertag"];
	[aCoder encodeObject:_gamerscore forKey:@"Gamerscore"];
	[aCoder encodeObject:_realName forKey:@"RealName"];
	[aCoder encodeObject:_motto forKey:@"Motto"];
	[aCoder encodeObject:_location forKey:@"Location"];
	[aCoder encodeObject:_bio forKey:@"Bio"];
	[aCoder encodeObject:_tileURL forKey:@"TileURL"];
}

- (TIXboxLiveEngineConnection *)connectionWithRequest:(NSMutableURLRequest *)request type:(TIXboxLiveEngineConnectionType)type {
	
	[request setDefaultsForHash:self.cookieHash];
	
	TIXboxLiveEngineConnection * connection = [[TIXboxLiveEngineConnection alloc] initWithRequest:request delegate:self];
	[connection setType:type];
	if (connection) [_returnDataDict setObject:[NSMutableData data] forKey:[NSValue valueWithNonretainedObject:connection]];
	return connection;
}

- (void)getGamerProfileWithCallback:(TIXboxLiveUserProfileBlock)callback {
	
	NSURL * profileURL = [NSURL URLWithString:@"https://live.xbox.com/en-GB/MyXbox/GamerProfile"];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:profileURL];
	[[self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetGamerProfile] setCallback:callback];
}

- (void)changeGamerProfileName:(NSString *)name motto:(NSString *)newMotto location:(NSString *)newLocation bio:(NSString *)newBio callback:(TIXboxLiveUserProfileBlock)callback {
	
	NSURL * profileURL = [NSURL URLWithString:@"https://live.xbox.com/en-GB/MyXbox/GamerProfile"];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:profileURL];
	
	[self setOldValues];
	[self setRealName:name];
	[self setMotto:newMotto];
	[self setLocation:newLocation];
	[self setBio:newBio];
	
	TIURLRequestParameter * verificationParameter = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:self.verificationToken];
	TIURLRequestParameter * nameParameter = [[TIURLRequestParameter alloc] initWithName:@"Name" value:name];
	TIURLRequestParameter * mottoParameter = [[TIURLRequestParameter alloc] initWithName:@"Motto" value:newMotto];
	TIURLRequestParameter * locationParameter = [[TIURLRequestParameter alloc] initWithName:@"Location" value:newLocation];
	TIURLRequestParameter * bioParameter = [[TIURLRequestParameter alloc] initWithName:@"Bio" value:newBio];
	[request setParameters:[NSArray arrayWithObjects:verificationParameter, nameParameter, mottoParameter, locationParameter, bioParameter, nil]];
	
	[[self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeChangeGamerProfile] setCallback:callback];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetGamerProfile){
		[self doCallbackForProfileReceived:xboxConnection];
	}
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeChangeGamerProfile){
		[self setRealName:_oldName];
		[self setMotto:_oldMotto];
		[self setLocation:_oldLocation];
		[self setBio:_oldBio];
		[self clearOldValues];
		[self doCallbackForProfileChangeSuccessfully:NO connection:xboxConnection];
	}
	
	[_returnDataDict removeObjectForKey:[NSValue valueWithNonretainedObject:connection]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(NSMutableData *)[_returnDataDict objectForKey:[NSValue valueWithNonretainedObject:connection]] appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[(NSMutableData *)[_returnDataDict objectForKey:[NSValue valueWithNonretainedObject:connection]] setLength:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	NSMutableData * returnData = [_returnDataDict objectForKey:[NSValue valueWithNonretainedObject:connection]];
	
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetGamerProfile){
		
		NSString * response = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
		
		dispatch_async_serial("com.TIXboxLiveEngine.UserProfileParseQueue", ^{
			
			[self setVerificationToken:[response stringBetween:@"<input name=\"__RequestVerificationToken\" type=\"hidden\" value=\"" and:@"\""]];
			[self setRealName:[response stringBetween:@"name=\"Name\" size=\"50\" type=\"text\" value=\"" and:@"\""]];
			[self setMotto:[response stringBetween:@"name=\"Motto\" size=\"50\" type=\"text\" value=\"" and:@"\""]];
			[self setLocation:[response stringBetween:@"name=\"Location\" size=\"50\" type=\"text\" value=\"" and:@"\""]];
			[self setBio:[[response stringBetween:@"rows=\"6\">" and:@"</textarea>"] 
						  stringByTrimmingWhitespaceAndNewLines]];
			
			dispatch_async_main_queue(^{[self doCallbackForProfileReceived:xboxConnection];});
		});
	}
	
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeChangeGamerProfile){
		
		NSString * response = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
		
		BOOL successful = [response contains:@"s Profile - Xbox.com"];
		if (!successful){
			[self setRealName:_oldName];
			[self setMotto:_oldMotto];
			[self setLocation:_oldLocation];
			[self setBio:_oldBio];
		}
		
		[self clearOldValues];
		
		[self doCallbackForProfileChangeSuccessfully:successful connection:xboxConnection];
	}
	
	[_returnDataDict removeObjectForKey:[NSValue valueWithNonretainedObject:connection]];
}

- (void)doCallbackForProfileReceived:(TIXboxLiveEngineConnection *)connection {
	
	TIXboxLiveUserProfileBlock profileBlock = connection.callback;
	if (profileBlock) profileBlock(nil);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:TIXboxLiveUserDidReceiveGamerProfileNotificationName object:connection];
}

- (void)doCallbackForProfileChangeSuccessfully:(BOOL)successfully connection:(TIXboxLiveEngineConnection *)connection {
	
	TIXboxLiveUserProfileBlock profileBlock = connection.callback;
	if (profileBlock) profileBlock(nil);
	
	NSDictionary * infoDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:successfully], @"Successfully", connection, @"Connection", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:TIXboxLiveUserDidFinishChangingGamerProfileNotificationName object:infoDict];
}

- (void)setOldValues {
	_oldName = [_realName copy];
	_oldMotto = [_motto copy];
	_oldLocation = [_location copy];
	_oldBio = [_bio copy];
}

- (void)clearOldValues {
	_oldName = nil;
	_oldMotto = nil;
	_oldLocation = nil;
	_oldBio = nil;
}

- (BOOL)isEqual:(id)object {
	
	if ([object isKindOfClass:[TIXboxLiveMessage class]]){
		return [_gamertag.lowercaseString isEqualToString:((TIXboxLiveMessage *)object).sender.lowercaseString];
	}
	
	if ([object isKindOfClass:[TIXboxLiveUser class]]) return [self isEqualToUser:object];
	if ([object isKindOfClass:[TIXboxLiveFriend class]]) return [self isEqualToFriend:object];
	
	return [super isEqual:object];
}

- (BOOL)isEqualToUser:(TIXboxLiveUser *)user {
	return (self == user || [_gamertag.lowercaseString isEqualToString:user.gamertag.lowercaseString]);
}

- (BOOL)isEqualToFriend:(TIXboxLiveFriend *)friend {
	return [friend hasGamertag:_gamertag];
}

@end
