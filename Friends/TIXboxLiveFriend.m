//
//  TIXboxLiveFriend.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveFriend.h"
#import "TIURLRequestParameter.h"
#import "TIXboxLiveEngineAdditions.h"
#import "TIXboxLiveEngineConnection.h"
#import "TIXboxLiveMessage.h"
#import "TIXboxLiveUser.h"

@interface TIXboxLiveFriend (Private)
- (TIXboxLiveEngineConnection *)connectionWithRequest:(NSMutableURLRequest *)request type:(TIXboxLiveEngineConnectionType)type;
- (NSURLConnection *)postConnectionWithAddress:(NSString *)address;
- (void)parseGamerInfo:(NSString *)gamerPage connection:(TIXboxLiveEngineConnection *)connection;
- (void)notifyDelegateOfGamerInfo:(NSDictionary *)gamerInfo forConnection:(TIXboxLiveEngineConnection *)connection;
@end

@implementation TIXboxLiveFriend
@synthesize gamertag;
@synthesize info;
@synthesize status;
@synthesize avatarURL;
@synthesize isOnFriendsList;
@synthesize friendRequestType;
@synthesize tileURL;

#pragma mark - Init / Copy Methods
- (id)init {
	
	if ((self = [super init])){
		returnDataDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (id)initWithGamertag:(NSString *)aGamertag info:(NSString *)someInfo status:(TIXboxLiveFriendStatus)someStatus tileURL:(NSURL *)aURL {
	
	if ((self = [self init])){
		
		gamertag = [aGamertag copy];
		info = [someInfo copy];
		status = someStatus;
		tileURL = [aURL retain];
		avatarURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"http://avatar.xboxlive.com/avatar/%@/avatar-body.png", gamertag.encodedURLString]];
		isOnFriendsList = YES;
		friendRequestType = TIXboxLiveFriendRequestTypeNone;
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [self init])){
		
		gamertag = [[aDecoder decodeObjectForKey:@"Gamertag"] copy];
		info = @"Waiting for refresh";
		status = TIXboxLiveFriendStatusUnknown;
		avatarURL = [[aDecoder decodeObjectForKey:@"AvatarURL"] retain];
		isOnFriendsList = [aDecoder decodeBoolForKey:@"IsOnFriendsList"];
		friendRequestType = TIXboxLiveFriendRequestTypeNone;
		tileURL = [[aDecoder decodeObjectForKey:@"TileURL"] retain];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:gamertag forKey:@"Gamertag"];
	[aCoder encodeBool:isOnFriendsList forKey:@"IsOnFriendsList"];
	[aCoder encodeObject:tileURL forKey:@"TileURL"];
	[aCoder encodeObject:avatarURL forKey:@"AvatarURL"];
}

- (id)copyWithZone:(NSZone *)zone {
	
	TIXboxLiveFriend * friend = [[[self class] allocWithZone:zone] init];
	[friend setGamertag:gamertag];
	[friend setInfo:info];
	[friend setStatus:status];
	[friend setAvatarURL:avatarURL];
	[friend setIsOnFriendsList:isOnFriendsList];
	[friend setTileURL:tileURL];
	
	return friend;
}

- (NSComparisonResult)compare:(TIXboxLiveFriend *)aFriend {
	
	if (status == aFriend.status){
		return [self statusInsensitiveCompare:aFriend];
	}
	else if (status == TIXboxLiveFriendStatusRequest){
		return NSOrderedAscending;
	}
	else if (status == TIXboxLiveFriendStatusOffline){
		return NSOrderedDescending;
	}
	else if (status == TIXboxLiveFriendStatusOnline){
		if (aFriend.status == TIXboxLiveFriendStatusRequest) return NSOrderedDescending;
		if (aFriend.status == TIXboxLiveFriendStatusOffline) return NSOrderedAscending;
	}
	
	return NSOrderedSame;
}

- (NSComparisonResult)statusInsensitiveCompare:(TIXboxLiveFriend *)aFriend {
	return [gamertag caseInsensitiveCompare:aFriend.gamertag];
}

+ (TIXboxLiveFriend *)friendWithGamertag:(NSString *)aGamertag {
	
	TIXboxLiveFriend * friend = [[TIXboxLiveFriend alloc] initWithGamertag:aGamertag info:@"Unknown" status:TIXboxLiveFriendStatusUnknown tileURL:nil];
	[friend setIsOnFriendsList:NO];
	return [friend autorelease];
}

#pragma mark - Connection Methods
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

- (NSURLConnection *)postConnectionWithAddress:(NSString *)address {
	
	NSURL * requestURL = [[NSURL alloc] initWithString:address];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
	[requestURL release];
	
	[request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
	[request setDefaultsForHash:self.cookieHash];
	
	TIURLRequestParameter * tagParameter = [[TIURLRequestParameter alloc] initWithName:@"gamerTag" value:gamertag];
	TIURLRequestParameter * verificationParameter = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:self.verificationToken];
	
	NSArray * params = [[NSArray alloc] initWithObjects:tagParameter, verificationParameter, nil];
	
	[tagParameter release];
	[verificationParameter release];
	
	[request setParameters:params];
	[params release];
	
	NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
	
	[request release];
	[connection release];
	
	return connection;
}

- (void)getGamerInfoWithCallback:(TIXboxLiveFriendGamerInfoBlock)callback {
	
	NSString * gamerAddress = [@"https://live.xbox.com/en-GB/MyXbox/Profile?gamertag=" stringByAppendingString:[gamertag encodedURLParameterString]];
	
	NSURL * URL = [[NSURL alloc] initWithString:gamerAddress];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:URL];
	[URL release];
	
	[[self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetFriendGamerInfo] setCallback:callback];
	[request release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetFriendGamerInfo){
		
		TIXboxLiveFriendGamerInfoBlock infoBlock = xboxConnection.callback;
		if (infoBlock) infoBlock(error, nil, nil, nil, nil, nil, nil);
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
	NSData * returnData = [returnDataDict objectForKey:[NSValue valueWithPointer:connection]];
	
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetFriendGamerInfo){
		
		NSString * response = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
		dispatch_async_serial("com.TIXboxLiveEngine.FriendProfileParseQueue", ^{[self parseGamerInfo:response connection:xboxConnection];});
		[response release];
	}
	
	[returnDataDict removeObjectForKey:[NSValue valueWithPointer:connection]];
}

#pragma mark - Helpers
- (void)parseGamerInfo:(NSString *)gamerPage connection:(TIXboxLiveEngineConnection *)connection {
	
	[gamerPage retain];
	[connection retain];
	
	NSString * realName = [gamerPage stringBetween:@"<div class=\"name\" title=\"" and:@"\""];
	NSString * location = [[[gamerPage stringBetween:@"<label>Location:</label>" and:@"</div>"] stringByTrimmingWhitespaceAndNewLines] 
						   stringByReplacingOccurrencesOfString:@"<div class=\"value\">" withString:@""];
	NSString * bio = [gamerPage stringBetween:@"<div class=\"value\" title=\"" and:@"\""];
	
	NSString * motto = [[gamerPage stringBetween:@"<div class=\"motto\">" and:@"<div class=\"bubble-arrow\""] stringByTrimmingWhitespaceAndNewLines];
	
	NSString * gamerscore = [gamerPage stringBetween:@"<div class=\"gamerscore\">" and:@"</div>"];
	NSString * newInfo = [[gamerPage stringBetween:@"<div class=\"presence\">" and:@"</div>"] stringByCorrectingDateRelativeToLocale];
	
	if (!tileURL) tileURL = [[NSURL alloc] initWithString:[gamerPage stringBetween:@"<img class=\"gamerpic\" src=\"" and:@"\""]];
	
	TIXboxLiveFriendGamerInfoBlock infoBlock = connection.callback;
	if (infoBlock) dispatch_async_main_queue(^{infoBlock(nil, realName, motto, location, bio, gamerscore, newInfo);});
	
	[gamerPage autorelease];
	[connection autorelease];
}

#pragma mark - Gamer Methods
- (NSString *)statusDescription {
	
	if (status == TIXboxLiveFriendStatusOnline) return @"Online";
	else if (status == TIXboxLiveFriendStatusOffline) return @"Offline";
	else if (status == TIXboxLiveFriendStatusRequest) return @"Pending";
	else return @"Unknown";
}

- (BOOL)isEqual:(id)object {
	
	if ([object isKindOfClass:[TIXboxLiveMessage class]]){
		return [gamertag.lowercaseString isEqualToString:((TIXboxLiveMessage *)object).sender.lowercaseString];
	}
	
	if ([object isKindOfClass:[TIXboxLiveFriend class]]) return [self isEqualToFriend:object];
	if ([object isKindOfClass:[TIXboxLiveUser class]]) return [(TIXboxLiveUser *)object isEqualToFriend:self];
	
	return [super isEqual:object];
}

- (BOOL)isEqualToFriend:(TIXboxLiveFriend *)aFriend {
	return (self == aFriend || [self hasGamertag:aFriend.gamertag]);
}

- (BOOL)hasGamertag:(NSString *)aGamertag {
	return [gamertag.lowercaseString isEqualToString:aGamertag.lowercaseString];
}

- (BOOL)removeFriend {
	
	NSString * removeAddress = @"https://live.xbox.com/en-GB/Friends/Remove";
	
	if (friendRequestType == TIXboxLiveFriendRequestTypeOutgoing){
		removeAddress = @"https://live.xbox.com/en-GB/Friends/Cancel";
	}
	
	if (friendRequestType == TIXboxLiveFriendRequestTypeIncoming){
		removeAddress = @"https://live.xbox.com/en-GB/Friends/Decline";
	}
	
	return ([self postConnectionWithAddress:removeAddress] != nil);
}

- (BOOL)handleFriendRequest:(BOOL)shouldAccept {
	
	NSString * requestAddress = @"https://live.xbox.com/en-GB/Friends/Accept";
	if (!shouldAccept) requestAddress = @"https://live.xbox.com/en-GB/Friends/Decline";
	
	return ([self postConnectionWithAddress:requestAddress] != nil);
}

- (NSString *)game {
	
	NSString * game = @"";
	
	if (status == TIXboxLiveFriendStatusOnline){
		
		game = [info stringBetween:@"playing " and:@" -"];
		if (!game.isNotEmpty){
			
			NSRange gameRange = [info rangeOfString:@"playing "];
			game = [[info substringFromIndex:(gameRange.location + gameRange.length)] stringByReplacingWeirdEncoding];
		}
	}
	
	return game;
}

- (BOOL)changedGame:(TIXboxLiveFriend *)oldFriend {
	
	if (oldFriend && ![self.game isEqualToString:@""]){
		return (![self.game isEqualToString:oldFriend.game] && 
				oldFriend.status == TIXboxLiveFriendStatusOnline && status == TIXboxLiveFriendStatusOnline);
	}
	
	return NO;
}

#pragma mark - Other Stuff
- (NSDictionary *)dictRepresentation {
	
	NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
	[dict safelySetObject:gamertag forKey:@"Gamertag"];
	[dict safelySetObject:info forKey:@"Info"];
	
	return [dict autorelease];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TIXboxLiveFriend %p; %@>", self, [self dictRepresentation]];
}

- (void)dealloc {
	[gamertag release];
	[info release];
	[avatarURL release];
	[returnDataDict release];
	[tileURL release];
	[super dealloc];
}

@end