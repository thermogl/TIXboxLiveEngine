//
//  TIXboxLiveEngineAdditions.h
//  TIXboxLiveEngine
//
//  Created by Tom Irving on 21/10/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineCookieStorage.h"

void dispatch_async_serial(const char * label, dispatch_block_t block);
void dispatch_async_main_queue(dispatch_block_t block);

@interface NSURL (TIXboxLiveEngineAdditions)
- (NSString *)safeBaseURL;
@end

@interface NSMutableURLRequest (TIXboxLiveEngineAdditions)
@property (nonatomic, retain) NSArray * parameters;
- (void)attachFile:(NSData *)fileData fileName:(NSString *)filename parameterName:(NSString *)parameterName contentType:(NSString *)contentType;
- (void)setDefaultsForHash:(NSString *)cookieHash;
@end

@interface NSString (TIXboxLiveEngineAdditions)
@property (nonatomic, readonly) BOOL isNotEmpty;
@property (nonatomic, readonly) NSString * encodedURLString;
@property (nonatomic, readonly) NSString * encodedURLParameterString;
@property (nonatomic, readonly) NSString * decodedURLString;
@property (nonatomic, readonly) NSString * stringByReplacingWeirdEncoding;
@property (nonatomic, readonly) NSString * stringByEscapingXML;
@property (nonatomic, readonly) NSString * stringByUnescapingXML;
@property (nonatomic, readonly) NSString * stringByTrimmingWhitespaceAndNewLines;
@property (nonatomic, readonly) NSString * stringByCorrectingDateRelativeToLocale;
@property (nonatomic, readonly) id objectFromJSONString;
@property (nonatomic, readonly) NSDate * dateFromJSONDate;
@property (nonatomic, readonly) NSString * fileSafeHash;

- (NSString *)stringBetween:(NSString *)start and:(NSString *)end;
- (BOOL)contains:(NSString *)string;
- (NSString *)stringByCorrectingDateRelativeToLocaleWithInputFormatter:(NSDateFormatter *)inputFormatter 
													   outputFormatter:(NSDateFormatter *)outputFormatter;
- (NSString *)stringSignedWithSecret:(NSString *)secret;

@end

@class TIXboxLiveFriend, TIXboxLiveGame, TIXboxLiveMessage;
@interface NSArray (TIXboxLiveEngineAdditions)

- (NSUInteger)indexOfFriendWithGamertag:(NSString *)gamertag;
- (NSUInteger)indexOfMessageWithID:(NSString *)address;

- (NSUInteger)indexOfFriendEqualToFriend:(TIXboxLiveFriend *)aFriend;
- (NSUInteger)indexOfMessageEqualToMessage:(TIXboxLiveMessage *)aMessage;

- (BOOL)containsFriendWithGamertag:(NSString *)gamertag;
- (BOOL)containsMessageWithID:(NSString *)address;

- (BOOL)containsFriendEqualToFriend:(TIXboxLiveFriend *)aFriend;
- (BOOL)containsMessageEqualToMessage:(TIXboxLiveMessage *)aMessage;

- (TIXboxLiveFriend *)friendWithGamertag:(NSString *)gamertag;
- (TIXboxLiveMessage *)messageWithID:(NSString *)messageID;
	
@end

@interface NSDictionary (TIXboxLiveEngineAdditions)
- (id)safeObjectForKey:(id)key;
@end
	
@interface NSMutableDictionary (TIXboxLiveEngineAdditions)
- (void)safelySetObject:(id)anObject forKey:(id)aKey;
@end

@interface NSDate (TIXboxLiveEngineAdditions)
- (NSString *)relativeDateString;
- (NSString *)relativeDateStringWithDateFormatter:(NSDateFormatter *)dateFormatter;
- (NSString *)fullDateString;
- (NSString *)fullDateStringWithDateFormatter:(NSDateFormatter *)dateFormatter;
@end

#if TARGET_OS_IPHONE
@interface UIApplication (TIXboxLiveEngineAdditions)
- (void)smartSetNetworkActivityIndicatorVisible:(BOOL)visible;
@end

@interface UIImage (TIXboxLiveEngineAdditions)
- (UIImage *)imageCroppedToRect:(CGRect)rect;
@end
#else
NSData * NSImagePNGRepresentation(NSImage * image);
NSData * NSImageJPEGRepresentation(NSImage * image, CGFloat compression);
@interface NSImage (TIXboxLiveEngineAdditions)
- (NSImage *)imageCroppedToRect:(NSRect)rect;
@end
#endif