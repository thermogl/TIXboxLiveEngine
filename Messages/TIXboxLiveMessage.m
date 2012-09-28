//
//  TIXboxLiveMessage.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 24/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveMessage.h"
#import "TIXboxLiveEngineAdditions.h"
#import "TIURLRequestParameter.h"
#import "TIXboxLiveEngineConnection.h"
#import "JSONKit.h"

@interface TIXboxLiveMessage (Private)
- (TIXboxLiveEngineConnection *)connectionWithRequest:(NSMutableURLRequest *)request type:(TIXboxLiveEngineConnectionType)type;
- (void)addParametersToRequest:(NSMutableURLRequest *)request;
@end

@implementation TIXboxLiveMessage
@synthesize messageID;
@synthesize sender;
@synthesize summary;
@synthesize date;
@synthesize readStatus;
@synthesize body;
@synthesize attachmentType;
@synthesize relativeDateStamp;
@synthesize fullDateStamp;

- (id)init {
	
	if ((self = [super init])){
		returnDataDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (id)initWithMessageID:(NSString *)anID sender:(NSString *)aSender summary:(NSString *)aSummary date:(NSDate *)aDate 
			 readStatus:(TIXboxLiveMessageReadStatus)aStatus attachmentType:(TIXboxLiveMessageAttachmentType)type {
	
	if ((self = [self init])){
		
		messageID = [anID copy];
		sender = [aSender copy];
		summary = [aSummary copy];
		date = [aDate copy];
		readStatus = aStatus;
		attachmentType = type;
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [self init])){
		
		messageID = [[aDecoder decodeObjectForKey:@"MessageID"] copy];
		sender = [[aDecoder decodeObjectForKey:@"Sender"] copy];
		summary = [[aDecoder decodeObjectForKey:@"Summary"] copy];
		date = [[aDecoder decodeObjectForKey:@"Date"] copy];
		readStatus = [aDecoder decodeIntegerForKey:@"ReadStatus"];
		body = [[aDecoder decodeObjectForKey:@"Body"] copy];
		attachmentType = [aDecoder decodeIntegerForKey:@"AttachmentType"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:messageID forKey:@"MessageID"];
	[aCoder encodeObject:sender forKey:@"Sender"];
	[aCoder encodeObject:summary forKey:@"Summary"];
	[aCoder encodeObject:date forKey:@"Date"];
	[aCoder encodeInteger:readStatus forKey:@"ReadStatus"];
	[aCoder encodeObject:body forKey:@"Body"];
	[aCoder encodeInteger:attachmentType forKey:@"AttachmentType"];
}

- (NSString *)relativeDateStamp {
	
	if (!relativeDateStamp)
		relativeDateStamp = [[date relativeDateString] copy];
	
	return relativeDateStamp;
}

- (NSString *)fullDateStamp {
	
	if (!fullDateStamp)
		fullDateStamp = [[date fullDateString] copy];
	
	return fullDateStamp;
}

- (BOOL)isEqual:(id)object {
	
	if ([object isKindOfClass:[TIXboxLiveMessage class]]) 
		return [self isEqualToMessage:object];
	
	return [object isEqual:self];
}

- (BOOL)isEqualToMessage:(TIXboxLiveMessage *)message {
	return (self == message || [self hasMessageID:message.messageID]);
}

- (BOOL)hasMessageID:(NSString *)anID {
	return [messageID isEqualToString:anID];
}

- (BOOL)isFriendRequest {
	return ([summary contains:@"Wants to be your friend"]);
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

- (void)addParametersToRequest:(NSMutableURLRequest *)request {
	
	NSMutableArray * parameters = [[NSMutableArray alloc] init];
	
	TIURLRequestParameter * parameter = [[TIURLRequestParameter alloc] initWithName:@"msgID" value:messageID];
	[parameters addObject:parameter];
	[parameter release];
	
	TIURLRequestParameter * parameter2 = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:self.verificationToken];
	[parameters addObject:parameter2];
	[parameter2 release];
	
	[request setParameters:parameters];
	[parameters release];
}

- (BOOL)deleteMessage {
	
	if ([self isFriendRequest]) return [self handleFriendRequest:NO];
	
	NSURL * deleteURL = [[NSURL alloc] initWithString:@"http://live.xbox.com/en-GB/Messages/Delete"];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:deleteURL];
	[deleteURL release];
	
	[request setDefaultsForHash:self.cookieHash];
	[self addParametersToRequest:request];
	
	NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
	
	[request release];
	[connection release];
	
	return (connection != nil);
}

- (BOOL)handleFriendRequest:(BOOL)shouldAccept {
	
	NSString * requestAddress = @"http://live.xbox.com/en-GB/Friends/Accept";
	if (!shouldAccept) requestAddress = @"http://live.xbox.com/en-GB/Friends/Decline";
	
	NSURL * requestURL = [[NSURL alloc] initWithString:requestAddress];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
	[requestURL release];
	
	[request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
	[request setDefaultsForHash:self.cookieHash];
	
	TIURLRequestParameter * verificationParameter = [[TIURLRequestParameter alloc] initWithName:@"__RequestVerificationToken" value:self.verificationToken];
	TIURLRequestParameter * gamertagParameter = [[TIURLRequestParameter alloc] initWithName:@"gamerTag" value:sender];
	
	NSArray * parameters = [[NSArray alloc] initWithObjects:verificationParameter, gamertagParameter, nil];
	[request setParameters:parameters];
	[parameters release];
	
	[verificationParameter release];
	[gamertagParameter release];
	
	NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
	
	[request release];
	[connection release];
	
	return (connection != nil);
}

- (void)downloadMessageWithBodyCallback:(TIXboxLiveMessageBodyBlock)bodyCallback imageCallback:(TIXboxLiveMessageImageBlock)imageCallback {
	
	NSURL * URL = [[NSURL alloc] initWithString:@"http://live.xbox.com/en-GB/Messages/Message"];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:URL];
	[URL release];
	
	[request setDefaultsForHash:self.cookieHash];
	[self addParametersToRequest:request];
	
	[[self connectionWithRequest:request type:TIXboxLiveEngineConnectionTypeGetMessageBody] setCallback:bodyCallback];
	[request release];
	
	if (attachmentType == TIXboxLiveMessageAttachmentTypeImage){
		
		NSURL * imageURL = [[NSURL alloc] initWithString:[@"http://live.xbox.com/en-GB/Messages/Image?msgId=" stringByAppendingString:messageID]];
		NSMutableURLRequest * imageRequest = [[NSMutableURLRequest alloc] initWithURL:imageURL];
		[imageURL release];
		
		[imageRequest setDefaultsForHash:self.cookieHash];
		[[self connectionWithRequest:imageRequest type:TIXboxLiveEngineConnectionTypeGetMessageImage] setCallback:imageCallback];
		[imageRequest release];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	TIXboxLiveEngineConnection * xboxConnection = (TIXboxLiveEngineConnection *)connection;
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetMessageBody){
		[self setBody:[error localizedDescription]];
		
		TIXboxLiveMessageBodyBlock bodyBlock = xboxConnection.callback;
		if (bodyBlock) bodyBlock(body);
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
	
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetMessageBody){
		
		NSString * response = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];		
		NSDictionary * contentDict = [[response objectFromJSONString] objectForKey:@"Data"];
		[response release];
		
		NSString * tempBody = [contentDict objectForKey:@"Text"];
		
		if (!tempBody.isNotEmpty && TIXboxLiveMessageAttachmentIsVoice(attachmentType))
			tempBody = @"Voice attachments can only be viewed on your console.";
		
		if (!tempBody) tempBody = @"An error occured when downloading the message";
		
		[self setBody:[(NSString *)tempBody stringByReplacingWeirdEncoding]];
		[self setReadStatus:TIXboxLiveMessageReadStatusRead];
		
		TIXboxLiveMessageBodyBlock bodyBlock = xboxConnection.callback;
		if (bodyBlock) bodyBlock(body);
	}
	
	/*
	if (xboxConnection.type == TIXboxLiveEngineConnectionTypeGetMessageImage){
#if TARGET_OS_IPHONE
		UIImage * image = [[UIImage alloc] initWithData:returnData];
#else
		NSImage * image = [[NSImage alloc] initWithData:returnData];
#endif
		[image release];
		
		TIXboxLiveMessageImageBlock imageBlock = xboxConnection.callback;
	}
	 */
	
	[returnDataDict removeObjectForKey:[NSValue valueWithPointer:connection]];
}

- (NSComparisonResult)compare:(TIXboxLiveMessage *)message {
	return [sender caseInsensitiveCompare:message.sender];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<TIXboxLiveMessage %p; sender = \"%@\"; summary = \"%@\">", self, sender, summary];
}

- (void)dealloc {
	[messageID release];
	[sender release];
	[summary release];
	[date release];
	[body release];
	[returnDataDict release];
	[relativeDateStamp release];
	[fullDateStamp release];
	[super dealloc];
}

@end