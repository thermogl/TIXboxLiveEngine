//
//  TIXboxLiveEngineAdditions.m
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineAdditions.h"
#import "TIURLRequestParameter.h"
#import <CommonCrypto/CommonHMAC.h>
#import "TIXboxLiveFriend.h"
#import	"TIXboxLiveGame.h"
#import "TIXboxLiveMessage.h"
#import "TIXboxLiveEngineCookieStorage.h"

void dispatch_async_serial(const char * label, dispatch_block_t block) {
	dispatch_queue_t queue = dispatch_queue_create(label, NULL);
	dispatch_async(queue, block);
	dispatch_release(queue);
}

void dispatch_async_main_queue(dispatch_block_t block) {
	dispatch_async(dispatch_get_main_queue(), block);
}

NSString * TIXboxLiveEngineFileSavePath(NSString * name) {
#if TARGET_OS_IPHONE
	return [NSHomeDirectory() stringByAppendingFormat:@"/Library/Caches/%@", name];
#else
	return [NSHomeDirectory() stringByAppendingFormat:@"/Library/Application Support/Friendz/Images/%@", name];
#endif
}

@implementation NSURL (TIXboxLiveEngineAdditions)
- (NSString *)safeBaseURL {
    return [[self.absoluteString componentsSeparatedByString:@"?"] objectAtIndex:0];
}
@end

@implementation NSMutableURLRequest (TIXboxLiveEngineAdditions)

- (BOOL)isMultipart {
	return [[self valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"multipart/form-data"];
}

- (BOOL)isMethodGetOrDelete {
	return ([self.HTTPMethod isEqualToString:@"GET"] || [self.HTTPMethod isEqualToString:@"DELETE"]);
}

- (NSArray *)parameters {
	
    NSString * encodedParams = self.URL.query;
	if (![self isMultipart] && ![self isMethodGetOrDelete]){
		encodedParams = [[[NSString alloc] initWithData:self.HTTPBody encoding:NSASCIIStringEncoding] autorelease];
	}
	
	if (encodedParams && ![encodedParams isEqualToString:@""]){
		
		NSArray * encodedParameterPairs = [encodedParams componentsSeparatedByString:@"&"];
		NSMutableArray * requestParameters = [[NSMutableArray alloc] init];
		
		[encodedParameterPairs enumerateObjectsUsingBlock:^(NSString * encodedPair, NSUInteger idx, BOOL *stop){
			
			NSArray * encodedPairElements = [encodedPair componentsSeparatedByString:@"="];
			
			if (encodedPairElements.count > 1){
				NSString * name = [[encodedPairElements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSString * value = [[encodedPairElements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				
				TIURLRequestParameter * parameter = [[TIURLRequestParameter alloc] initWithName:name value:value];
				[requestParameters addObject:parameter];
				[parameter release];
			}
		}];
		
		return [requestParameters autorelease];
    }
    
    return nil;
}

- (void)setParameters:(NSArray *)parameters {
	
	NSMutableArray * pairs = [[NSMutableArray alloc] init];
	
	[parameters enumerateObjectsUsingBlock:^(TIURLRequestParameter * requestParameter, NSUInteger idx, BOOL *stop){
		[pairs addObject:[requestParameter safeURLRepresentation]];
	}];
	
	NSString * encodedParameterPairs = [pairs componentsJoinedByString:@"&"];
	[pairs release];
	
	NSData * bodyData = [encodedParameterPairs dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	
	NSString * length = [[NSString alloc] initWithFormat:@"%d", (int)bodyData.length];
	[self setValue:length forHTTPHeaderField:@"Content-Length"];
	[length release];
	
	[self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[self setHTTPBody:bodyData];
	[self setHTTPMethod:@"POST"];
}

- (void)attachFile:(NSData *)fileData fileName:(NSString *)filename parameterName:(NSString *)parameterName contentType:(NSString *)contentType {
	
	NSString * boundary = @"0xKhTmLbOuNdArY";
	[self setValue:[@"multipart/form-data; boundary=" stringByAppendingString:boundary] forHTTPHeaderField:@"Content-type"];
	
	NSMutableData * bodyData = [[NSMutableData alloc] init];
	NSArray * parameters = [self parameters];
	
	[parameters enumerateObjectsUsingBlock:^(TIURLRequestParameter * requestParameter, NSUInteger idx, BOOL *stop){
		
		NSString * parameterString = [[NSString alloc] initWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", boundary, 
									  requestParameter.name, requestParameter.value];
		[bodyData appendData:[parameterString dataUsingEncoding:NSUTF8StringEncoding]];
		[parameterString release];
	}];
	
	NSString * fileInfo = [[NSString alloc] initWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\n\r\n",
						   boundary, parameterName, filename, contentType];
	[bodyData appendData:[fileInfo dataUsingEncoding:NSUTF8StringEncoding]];
	[fileInfo release];
	
	[bodyData appendData:fileData];
	
	NSString * endSeparator = [[NSString alloc] initWithFormat:@"--%@--", boundary];
	[bodyData appendData:[endSeparator dataUsingEncoding:NSUTF8StringEncoding]];
	[endSeparator release];
	
	NSString * length = [[NSString alloc] initWithFormat:@"%d", (int)bodyData.length];
	[self setValue:length forHTTPHeaderField:@"Content-Length"];
	[length release];
	
	[self setHTTPBody:bodyData];
	[self setHTTPMethod:@"POST"];
	[bodyData release];
}

- (void)setDefaultsForHash:(NSString *)cookieHash {
	
	[self setHTTPShouldHandleCookies:NO];
	
	[self setTimeoutInterval:45];
	[self setValue:@"en-gb" forHTTPHeaderField:@"Accept-Language"];
	
	NSMutableString * cookieString = [[NSMutableString alloc] init];
	 
	[[TIXboxLiveEngineCookieStorage sharedCookieStorage] enumerateCookiesForURL:self.URL hash:cookieHash block:^(NSHTTPCookie * cookie){
		[cookieString appendFormat:@"%@=%@; ", cookie.name, cookie.value];
	 }];
	
	if ([cookieString isNotEmpty]) [self setValue:cookieString forHTTPHeaderField:@"Cookie"];
	[cookieString release];
}

@end

@interface NSString (Base64)
- (NSString *)stringByBase64Encoding:(const uint8_t *)input ofLength:(NSInteger)length;
@end

@implementation NSString (TIXboxLiveEngineAdditions)

- (NSString *)stringBetween:(NSString *)start and:(NSString *)end {
	
	@try {
		if (start && end){
			
			NSRange startRange = [self rangeOfString:start];
			if (startRange.location != NSNotFound){
				
				NSInteger offset = NSMaxRange(startRange);
				NSRange searchRange = [self rangeOfString:end options:0 range:NSMakeRange(offset, self.length - offset)];
				
				if (searchRange.location != NSNotFound){
					
					NSString * finalString = [self substringWithRange:NSMakeRange(offset, searchRange.location - offset)];
					if (finalString) return [[finalString stringByReplacingWeirdEncoding] stringByUnescapingXML];
				}
			}
		}
	}
	
	@catch(NSException *exception){}
	
	return @"";
}

- (BOOL)contains:(NSString *)string {
	return (string && [self rangeOfString:string].location != NSNotFound);
}

- (BOOL)isNotEmpty {
	return (self.length > 0 && [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0);
}

- (NSString *)encodedURLString {
	return [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, (CFStringRef)@"?=&+", 
																kCFStringEncodingUTF8) autorelease];
}

- (NSString *)encodedURLParameterString {
    return [(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, (CFStringRef)@":/=,!$&'()*+;[]@#?", 
																kCFStringEncodingUTF8) autorelease];
}

- (NSString *)decodedURLString {
	return [(NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef)self, CFSTR(""), 
																				kCFStringEncodingUTF8) autorelease];
}

- (NSString *)stringByReplacingWeirdEncoding {
	
	NSScanner * scanner = [[NSScanner alloc] initWithString:self];
	[scanner setCharactersToBeSkipped:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
	
	NSMutableString * replacedString = [[NSMutableString alloc] initWithString:self];
	
	int anInt;
	while (!scanner.isAtEnd){
		if ([scanner scanInt:&anInt]){
			
			NSString * formatString = [[NSString alloc] initWithFormat:@"&#%d;", anInt];
			
			if ([replacedString contains:formatString]){
				NSString * replacementString = [[NSString alloc] initWithFormat:@"%C", (unsigned short)anInt];
				[replacedString replaceOccurrencesOfString:formatString withString:replacementString options:NSAnchoredSearch range:NSMakeRange(0, replacedString.length)];
				[replacementString release];
			}
			
			[formatString release];
		}
	}
	
	[scanner release];
	return [replacedString autorelease];
}

- (NSString *)stringByEscapingXML {
	
	return [[[[[self stringByReplacingOccurrencesOfString: @"&" withString: @"&amp;"] 
			   stringByReplacingOccurrencesOfString: @"\"" withString: @"&quot;"] 
			  stringByReplacingOccurrencesOfString: @"'" withString: @"&#39;"] 
			 stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"] 
			stringByReplacingOccurrencesOfString: @"<" withString: @"&lt;"];
}

- (NSString *)stringByUnescapingXML {
	
	return [[[[[self stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"] 
			   stringByReplacingOccurrencesOfString: @"&quot;" withString: @"\""] 
			  stringByReplacingOccurrencesOfString: @"&#39;" withString: @"'"] 
			 stringByReplacingOccurrencesOfString: @"&gt;" withString: @">"] 
			stringByReplacingOccurrencesOfString: @"&lt;" withString: @"<"];
}

- (NSString *)stringByTrimmingWhitespaceAndNewLines {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)stringByCorrectingDateRelativeToLocale {
	return [self stringByCorrectingDateRelativeToLocaleWithInputFormatter:nil outputFormatter:nil];
}

- (NSString *)stringByCorrectingDateRelativeToLocaleWithInputFormatter:(NSDateFormatter *)inputFormatter outputFormatter:(NSDateFormatter *)outputFormatter {
	
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	
	BOOL shouldReleaseInputFormatter = NO;
	BOOL shouldReleaseOutputFormatter = NO;
	
	if (!inputFormatter){
		inputFormatter = [[NSDateFormatter alloc] init];
		[inputFormatter setDateFormat:@"dd/MM/yyyy"];
		shouldReleaseInputFormatter = YES;
	}
	
	if (!outputFormatter){
		outputFormatter = [[NSDateFormatter alloc] init];
		[outputFormatter setDateStyle:NSDateFormatterShortStyle];
		shouldReleaseOutputFormatter = YES;
	}
	
	NSString * info = [NSString stringWithString:self];
	
	if ([info contains:@"Last seen "]){
		NSString * dateString = [info stringBetween:@"Last seen " and:@" "];
		NSString * newDateString = [outputFormatter stringFromDate:[inputFormatter dateFromString:dateString]];
		if (newDateString) info = [info stringByReplacingOccurrencesOfString:dateString withString:newDateString];
	}
	
	if (shouldReleaseInputFormatter) [inputFormatter release];
	if (shouldReleaseOutputFormatter) [outputFormatter release];
	
	return info;
}

- (NSString *)stringSignedWithSecret:(NSString *)secret {
	
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA1, secret.UTF8String, secret.length, self.UTF8String, self.length, result);
	
	return [self stringByBase64Encoding:result length:CC_SHA1_DIGEST_LENGTH];
}

static char EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

- (NSString *)stringByBase64Encoding:(const uint8_t *)input length:(NSInteger)length {
	
	NSMutableData * data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t * output = (uint8_t *)data.mutableBytes;
	
    for (NSInteger i = 0; i < length; i += 3){
		NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++){
            value <<= 8;
            if (j < length) value |= (0xFF & input[j]);
        }
		
        NSInteger index = (i / 3) * 4;
        output[index] = EncodingTable[(value >> 18) & 0x3F];
        output[index + 1] = EncodingTable[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? EncodingTable[(value >> 6) & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? EncodingTable[(value >> 0) & 0x3F] : '=';
    }
	
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

- (NSDate *)dateFromJSONDate {
	return [NSDate dateWithTimeIntervalSince1970:([[self stringBetween:@"Date(" and:@")"] doubleValue] / 1000)];
}

- (NSString *)fileSafeHash {
	
	NSString * tempHash = [self stringSignedWithSecret:@"hash"];
	NSCharacterSet * illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
	return [[tempHash componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
}

@end

@implementation NSArray (TIXboxLiveEngineAdditions)

- (NSUInteger)indexOfFriendWithGamertag:(NSString *)gamertag {
	
	__block NSUInteger index = NSNotFound;
	[self enumerateObjectsUsingBlock:^(TIXboxLiveFriend * friend, NSUInteger idx, BOOL *stop){
		if ([friend hasGamertag:gamertag]){
			index = idx;
			*stop = YES;
		}
	}];
	
	return index;
}

- (NSUInteger)indexOfFriendEqualToFriend:(TIXboxLiveFriend *)aFriend {
	return [self indexOfFriendWithGamertag:aFriend.gamertag];
}

- (NSUInteger)indexOfGameEqualToGame:(TIXboxLiveGame *)aGame {
	
	__block NSUInteger index = NSNotFound;
	[self enumerateObjectsUsingBlock:^(TIXboxLiveGame * game, NSUInteger idx, BOOL *stop){
		if ([game isEqualToGame:aGame]){
			index = idx;
			*stop = YES;
		}
	}];
	
	return index;
}

- (NSUInteger)indexOfMessageWithID:(NSString *)anID {
	
	__block NSUInteger index = NSNotFound;
	[self enumerateObjectsUsingBlock:^(TIXboxLiveMessage * message, NSUInteger idx, BOOL *stop){
		if ([message hasMessageID:anID]){
			index = idx;
			*stop = YES;
		}
	}];
	
	return index;
}

- (NSUInteger)indexOfMessageEqualToMessage:(TIXboxLiveMessage *)aMessage {
	return [self indexOfMessageWithID:aMessage.messageID];
}

- (BOOL)containsFriendWithGamertag:(NSString *)gamertag {
	return ([self indexOfFriendWithGamertag:gamertag] != NSNotFound);
}

- (BOOL)containsMessageWithID:(NSString *)anID {
	return ([self indexOfMessageWithID:anID] != NSNotFound);
}

- (BOOL)containsFriendEqualToFriend:(TIXboxLiveFriend *)aFriend {
	return ([self indexOfFriendEqualToFriend:aFriend] != NSNotFound);
}

- (BOOL)containsMessageEqualToMessage:(TIXboxLiveMessage *)aMessage {
	return ([self indexOfMessageEqualToMessage:aMessage] != NSNotFound);
}

- (TIXboxLiveFriend *)friendWithGamertag:(NSString *)gamertag {
	
	NSUInteger index = [self indexOfFriendWithGamertag:gamertag];
	return (index == NSNotFound) ? nil : (TIXboxLiveFriend *)[self objectAtIndex:index];
}

- (TIXboxLiveMessage *)messageWithID:(NSString *)messageID {
	
	NSUInteger index = [self indexOfMessageWithID:messageID];
	return (index == NSNotFound) ? nil : (TIXboxLiveMessage *)[self objectAtIndex:index];
}

@end

@implementation NSDictionary (TIXboxLiveEngineAdditions)

- (id)safeObjectForKey:(id)key {
	id object = [self objectForKey:key];
	if ([object isEqual:[NSNull null]]) object = nil;
	return object;
}

@end

@implementation NSMutableDictionary (TIXboxLiveEngineAdditions)

- (void)safelySetObject:(id)anObject forKey:(id)aKey {
	if (anObject && aKey) [self setObject:anObject forKey:aKey];
}

@end

@implementation NSDate (TIXboxLiveEngineAdditions)

- (NSString *)relativeDateString {
	return [self relativeDateStringWithDateFormatter:nil];
}

- (NSString *)relativeDateStringWithDateFormatter:(NSDateFormatter *)dateFormatter {
	
	BOOL shouldReleaseFormatter = NO;
	if (!dateFormatter){
		dateFormatter = [[NSDateFormatter alloc] init];
		shouldReleaseFormatter = YES;
	}
	
	NSDate * now = [NSDate date];
	
	NSCalendar * calendar = [NSCalendar currentCalendar];
	NSDateComponents * offsetComponents = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:now];
	NSComparisonResult todayComparison = [self compare:[calendar dateFromComponents:offsetComponents]];
	
	[offsetComponents setDay:(offsetComponents.day - 1)];
	NSComparisonResult yesterdayComparison = [self compare:[calendar dateFromComponents:offsetComponents]];
	
	NSString * displayString = nil;
	
	if (todayComparison == NSOrderedDescending){
		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	}
	else if (todayComparison == NSOrderedSame){
		displayString = [dateFormatter stringFromDate:self];
	}
	else if (yesterdayComparison == NSOrderedSame || yesterdayComparison == NSOrderedDescending){
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		[dateFormatter setDoesRelativeDateFormatting:YES];
		displayString = [dateFormatter stringFromDate:self];
	}
	else
	{
		// check if date is within last 7 days
		NSDateComponents * componentsToSubtract = [[NSDateComponents alloc] init];
		[componentsToSubtract setDay:-7];
		
		NSDate * lastweek = [calendar dateByAddingComponents:componentsToSubtract toDate:now options:0];
		[componentsToSubtract release];
		
		if ([self compare:lastweek] == NSOrderedDescending){
			[dateFormatter setDateFormat:@"EEEE"];
		} 
		else
		{
			[dateFormatter setDateStyle:NSDateFormatterShortStyle];
			[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		}
	}
	
	if (!displayString) displayString = [dateFormatter stringFromDate:self];
	if (shouldReleaseFormatter)[dateFormatter release];
	
	return displayString;
}

- (NSString *)fullDateString {
	return [self fullDateStringWithDateFormatter:nil];
}

- (NSString *)fullDateStringWithDateFormatter:(NSDateFormatter *)dateFormatter {
	
	BOOL shouldReleaseFormatter = NO;
	
	if (!dateFormatter){
		dateFormatter = [[NSDateFormatter alloc] init];
		shouldReleaseFormatter = YES;
	}
	
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	NSString * fullDate = [dateFormatter stringFromDate:self];
	if (shouldReleaseFormatter) [dateFormatter release];
	
	return [fullDate stringByReplacingOccurrencesOfString:@"," withString:@""];
}

@end

#if TARGET_OS_IPHONE
@implementation UIApplication (TIXboxLiveEngineAdditions)

static int activityCounter = 0;
- (void)smartSetNetworkActivityIndicatorVisible:(BOOL)visible {
	
	if (visible) activityCounter++;
	else activityCounter--;
	
	if (activityCounter < 0) activityCounter = 0;
	[self setNetworkActivityIndicatorVisible:(activityCounter > 0)];
}

@end

@implementation UIImage (TIXboxLiveEngineAdditions)

- (UIImage *)imageCroppedToRect:(CGRect)rect {
	
	CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
	UIImage * finalImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	return finalImage;
}
@end
#else
NSData * NSImageDataRepresentation(NSImage * image, NSBitmapImageFileType type, CGFloat compression){
	
	NSDictionary * properties = (type == NSPNGFileType ? nil : [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:compression] 
																						   forKey:NSImageCompressionFactor]);
	NSBitmapImageRep * bitmapRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
	NSData * data = [bitmapRep representationUsingType:type properties:properties];
	[bitmapRep release];
	
	return data;
}

NSData * NSImagePNGRepresentation(NSImage * image) {
	return NSImageDataRepresentation(image, NSPNGFileType, 0);
}

NSData * NSImageJPEGRepresentation(NSImage * image, CGFloat compression) {
	return NSImageDataRepresentation(image, NSJPEGFileType, compression);
}

@implementation NSImage (TIXboxLiveEngineAdditions)

- (NSImage *)imageCroppedToRect:(NSRect)rect {
	
	NSAffineTransform * transform = [NSAffineTransform transform];
    [transform translateXBy:-rect.origin.x yBy:-rect.origin.y];
	
    NSImage * croppedImage = [[NSImage alloc] initWithSize:[transform transformSize:rect.size]];
    [croppedImage lockFocus];
    [transform concat];
	[self drawAtPoint:NSZeroPoint fromRect:(NSRect){NSZeroPoint, self.size} operation:NSCompositeCopy fraction:1.0];
    [croppedImage unlockFocus];
	
    return [croppedImage autorelease];
}

@end
#endif