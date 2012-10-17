//
//  TIXboxLiveMessageParser.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 24/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveMessagesParser.h"
#import "TIXboxLiveEngineAdditions.h"
#import "TIXboxLiveMessage.h"

@implementation TIXboxLiveMessagesParser

- (void)parseMessagesPage:(NSString *)aPage  callback:(TIXboxLiveMessagesParserMessagesBlock)callback {
	
	dispatch_async_serial("com.TIXboxLiveEngine.MessagesParseQueue", ^{
		
		NSDateFormatter * relativeFormatter = [[NSDateFormatter alloc] init];
		NSDateFormatter * fullFormatter = [[NSDateFormatter alloc] init];
		
		NSMutableArray * messages = [[NSMutableArray alloc] init];
		
		NSString * messagesJSON = [[aPage stringBetween:@"var mc = " and:@";"] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
		NSDictionary * messageData = [(NSDictionary *)[messagesJSON objectFromJSONString] safeObjectForKey:@"Data"];
		
		NSArray * rawRequests = [messageData safeObjectForKey:@"FriendRequests"];
		[rawRequests enumerateObjectsUsingBlock:^(NSDictionary * rawRequest, NSUInteger idx, BOOL *stop){
			
			NSDate * date = [[rawRequest safeObjectForKey:@"SentTime"] dateFromJSONDate];
			
			TIXboxLiveMessage * message = [[TIXboxLiveMessage alloc] initWithMessageID:[[rawRequest safeObjectForKey:@"Id"] stringValue]
																				sender:[rawRequest safeObjectForKey:@"From"] 
																			   summary:@"Wants to be your friend"
																				  date:[[rawRequest safeObjectForKey:@"SentTime"] dateFromJSONDate]
																			readStatus:TIXboxLiveMessageReadStatusUnread
																		attachmentType:TIXboxLiveMessageAttachmentTypeNone];
			[message setCookieHash:self.cookieHash];
			[message setVerificationToken:self.verificationToken];
			[message setRelativeDateStamp:[date relativeDateStringWithDateFormatter:relativeFormatter]];
			[message setFullDateStamp:[date fullDateStringWithDateFormatter:fullFormatter]];
			[messages addObject:message];
			[message release];
		}];
		
		NSArray * rawMessages = [messageData safeObjectForKey:@"Messages"];
		[rawMessages enumerateObjectsUsingBlock:^(NSDictionary * rawMessage, NSUInteger idx, BOOL *stop){
			
			TIXboxLiveMessageReadStatus status = [[rawMessage safeObjectForKey:@"HasBeenRead"] boolValue] ? 
			TIXboxLiveMessageReadStatusRead : TIXboxLiveMessageReadStatusUnread;
			
			TIXboxLiveMessageAttachmentType type = TIXboxLiveMessageAttachmentTypeNone;
			if ([[rawMessage safeObjectForKey:@"HasImage"] boolValue]) type = TIXboxLiveMessageAttachmentTypeImage;
			if ([[rawMessage safeObjectForKey:@"HasVoice"] boolValue]) type = (type == TIXboxLiveMessageAttachmentTypeImage ? 
																		   TIXboxLiveMessageAttachmentTypeBoth : TIXboxLiveMessageAttachmentTypeVoice);
			
			NSString * summary = [[rawMessage safeObjectForKey:@"Excerpt"] stringByReplacingWeirdEncoding];
			
			if (![[rawMessage safeObjectForKey:@"HasText"] boolValue]){
				if (type == TIXboxLiveMessageAttachmentTypeBoth) summary = @"Image and Voice attachments";
				if (type == TIXboxLiveMessageAttachmentTypeImage) summary = @"Image attachment";
				if (type == TIXboxLiveMessageAttachmentTypeVoice) summary = @"Voice attachment";
			}
			
			NSDate * date = [[rawMessage safeObjectForKey:@"SentTime"] dateFromJSONDate];
			
			TIXboxLiveMessage * message = [[TIXboxLiveMessage alloc] initWithMessageID:[[rawMessage safeObjectForKey:@"Id"] stringValue]
																				sender:[rawMessage safeObjectForKey:@"From"] 
																			   summary:summary
																				  date:date
																			readStatus:status
																		attachmentType:type];
			[message setCookieHash:self.cookieHash];
			[message setVerificationToken:self.verificationToken];
			[message setRelativeDateStamp:[date relativeDateStringWithDateFormatter:relativeFormatter]];
			[message setFullDateStamp:[date fullDateStringWithDateFormatter:fullFormatter]];
			[messages addObject:message];
			[message release];
		}];
		
		[fullFormatter release];
		[relativeFormatter release];
		
		dispatch_async_main_queue(^{callback(messages);});
		[messages release];
	});
}

@end