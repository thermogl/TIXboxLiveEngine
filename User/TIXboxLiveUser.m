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

@implementation TIXboxLiveUser
@synthesize gamertag;
@synthesize gamerscore;
@synthesize realName;
@synthesize motto;
@synthesize location;
@synthesize bio;
@synthesize tileURL;

- (id)init {
	
	if ((self = [super init])){
		
		oldName = nil;
		oldMotto = nil;
		oldLocation = nil;
		oldBio = nil;
		returnDataDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (id)initWithGamertag:(NSString *)aTag gamerscore:(NSString *)aScore tileURL:(NSURL *)aURL {
	
	if ((self = [self init])){
		gamertag = [aTag copy];
		gamerscore = [aScore copy];
		tileURL = [aURL retain];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [self init])){
		
		gamertag = [[aDecoder decodeObjectForKey:@"Gamertag"] copy];
		gamerscore = [[aDecoder decodeObjectForKey:@"Gamerscore"] copy];
		realName = [[aDecoder decodeObjectForKey:@"RealName"] copy];
		motto = [[aDecoder decodeObjectForKey:@"Motto"] copy];
		location = [[aDecoder decodeObjectForKey:@"Location"] copy];
		bio = [[aDecoder decodeObjectForKey:@"Bio"] copy];
		tileURL = [[aDecoder decodeObjectForKey:@"TileURL"] retain];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:gamertag forKey:@"Gamertag"];
	[aCoder encodeObject:gamerscore forKey:@"Gamerscore"];
	[aCoder encodeObject:realName forKey:@"RealName"];
	[aCoder encodeObject:motto forKey:@"Motto"];
	[aCoder encodeObject:location forKey:@"Location"];
	[aCoder encodeObject:bio forKey:@"Bio"];
	[aCoder encodeObject:tileURL forKey:@"TileURL"];
}

- (TIXboxLiveEngineConnection *)connectionWithRequest:(NSMutableURLRequest *)request type:(TIXboxLiveEngineConnectionType)type {
	
	[request setDefaultsForHash:self.cookieHash];
	
	TIXboxLiveEngineConnection * connection = [[TIXboxLiveEngineConnection alloc] initWithRequest:request delegate:self];
	[connection setType:type];
	
	if (connection){
		NSMutableData * data = [[NSMutableData alloc] init];
		[returnDataDict setObject:data forKey:[NSValue valueWithPointer:connection]];
		[data release];
	}
	
	[connection release];
	return connection;
}

- (void)getGamerProfileWithCallback:(TIXboxLiveUserProfileBlock)callback {
	
	NSURL * profileURL = [[NSURL alloc] initWithString:@"http://live.xbox.com/en-GB/MyXbox/GamerProfile"];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:profileURL];
	[profileURL release];
	
	[[self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetGamerProfile] setCallback:callback];
	[request release];
}

- (void)changeGamerProfileName:(NSString *)name motto:(NSString *)newMotto location:(NSString *)newLocation bio:(NSString *)newBio callback:(TIXboxLiveUserProfileBlock)callback {
	
	NSURL * profileURL = [[NSURL alloc] initWithString:@"http://live.xbox.com/en-GB/MyXbox/GamerProfile"];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:profileURL];
	[profileURL release];
	
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
	
	NSArray * parameters = [[NSArray alloc] initWithObjects:verificationParameter, nameParameter, mottoParameter, locationParameter, bioParameter, nil];
	
	[verificationParameter release];
	[nameParameter release];
	[mottoParameter release];
	[locationParameter release];
	[bioParameter release];
	
	[request setParameters:parameters];
	[parameters release];
	
	[[self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeChangeGamerProfile] setCallback:callback];
	[request release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetGamerProfile){
		[self doCallbackForProfileReceived:xboxConnection];
	}
	else if (xboxConnection.type == TIXboxLiveEngineConnectionTypeChangeGamerProfile){
		[self setRealName:oldName];
		[self setMotto:oldMotto];
		[self setLocation:oldLocation];
		[self setBio:oldBio];
		[self clearOldValues];
		[self doCallbackForProfileChangeSuccessfully:NO connection:xboxConnection];
	}
	
	[returnDataDict removeObjectForKey:[NSValue valueWithPointer:connection]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(NSMutableData *)[returnDataDict objectForKey:[NSValue valueWithPointer:connection]] appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[(NSMutableData *)[returnDataDict objectForKey:[NSValue valueWithPointer:connection]] setLength:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	NSMutableData * returnData = [returnDataDict objectForKey:[NSValue valueWithPointer:connection]];
	
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
		
		[response release];
	}
	
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeChangeGamerProfile){
		
		NSString * response = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
		
		BOOL successful = [response contains:@"s Profile - Xbox.com"];
		if (!successful){
			[self setRealName:oldName];
			[self setMotto:oldMotto];
			[self setLocation:oldLocation];
			[self setBio:oldBio];
		}
		
		[self clearOldValues];
		
		[self doCallbackForProfileChangeSuccessfully:successful connection:xboxConnection];
		[response release];
	}
	
	[returnDataDict removeObjectForKey:[NSValue valueWithPointer:connection]];
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
	
	[oldName release];
	oldName = [realName copy];
	
	[oldMotto release];
	oldMotto = [motto copy];
	
	[oldLocation release];
	oldLocation = [location copy];
	
	[oldBio release];
	oldBio = [bio copy];
}

- (void)clearOldValues {
	
	[oldName release];
	oldName = nil;
		
	[oldMotto release];
	oldMotto = nil;
		
	[oldLocation release];
	oldLocation = nil;
		
	[oldBio release];
	oldBio = nil;
}

- (BOOL)isEqual:(id)object {
	
	if ([object isKindOfClass:[TIXboxLiveMessage class]]){
		return [gamertag.lowercaseString isEqualToString:((TIXboxLiveMessage *)object).sender.lowercaseString];
	}
	
	if ([object isKindOfClass:[TIXboxLiveUser class]]) return [self isEqualToUser:object];
	if ([object isKindOfClass:[TIXboxLiveFriend class]]) return [self isEqualToFriend:object];
	
	return [super isEqual:object];
}

- (BOOL)isEqualToUser:(TIXboxLiveUser *)user {
	return (self == user || [gamertag.lowercaseString isEqualToString:user.gamertag.lowercaseString]);
}

- (BOOL)isEqualToFriend:(TIXboxLiveFriend *)friend {
	return [friend hasGamertag:gamertag];
}

- (void)dealloc {
	[self clearOldValues];
	[gamertag release];
	[gamerscore release];
	[realName release];
	[motto release];
	[location release];
	[bio release];
	[tileURL release];
	[returnDataDict release];
	[super dealloc];
}

@end
