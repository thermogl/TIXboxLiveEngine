//
//  TIXboxLiveEngineImageCache.m
//  Friendz
//
//  Created by Tom Irving on 13/09/2012.
//  Copyright (c) 2012 Tom Irving. All rights reserved.
//

#import "TIXboxLiveEngineImageCache.h"
#import "TIXboxLiveEngineConnection.h"
#import <CommonCrypto/CommonHMAC.h>

NSInteger const kTIXboxLiveEngineMaxImageCount = 10;
NSTimeInterval const kTIXboxLiveEngineImageCacheTime = 60 * 60 * 24;
NSString * const kTIXboxLiveEngineConnectionCacheKeyKey = @"TIXboxLiveEngineConnectionCacheKeyKey";
NSString * const kTIXboxLiveEngineConnectionURLKey = @"TIXboxLiveEngineConnectionURLKey";

@interface TIXboxLiveEngineImageCache () <NSURLConnectionDelegate>
- (NSString *)cacheKeyForURL:(NSURL *)URL;
- (NSString *)filePathForKey:(NSString *)key;
- (void)downloadImageAtURL:(NSURL *)URL key:(NSString *)key completionBlock:(TIXboxLiveEngineImageCacheCompletionBlock)block;
- (void)storeImageInMemoryCache:(id)image key:(NSString *)key;
- (void)writeImageData:(NSData *)imageData image:(id)image toPathWithKey:(NSString *)key completion:(dispatch_block_t)completion;
@end

@implementation TIXboxLiveEngineImageCache
@synthesize cacheRootDirectory;

#pragma mark - Instance Methods
- (id)init {
	
	if ((self = [super init])){
		memoryCache	= [[NSMutableDictionary alloc] init];
		returnDataDict = [[NSMutableDictionary alloc] init];
		processingQueue = dispatch_queue_create("com.TIXboxLiveEngineImageCache.ProcessingQueue", NULL);
		ioQueue = dispatch_queue_create("com.TIXboxLiveEngineImageCache.IOQueue", NULL);
		emptyingDiskCache = NO;
#if TARGET_OS_IPHONE
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emptyMemoryCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
	}
	
	return self;
}

- (BOOL)getImageForURL:(NSURL *)URL completion:(TIXboxLiveEngineImageCacheCompletionBlock)block {
	
	id image = nil;
	BOOL needsDownload = YES;
	
	if (URL && !emptyingDiskCache){
		
		needsDownload = NO;
		NSString * cacheKey = [self cacheKeyForURL:URL];
		NSString * filePath = [self filePathForKey:cacheKey];
		
		if (!(image = [memoryCache objectForKey:cacheKey])){
			needsDownload = YES;
			
			NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
			if (attributes){
				NSDate * modificationDate = [attributes objectForKey:NSFileModificationDate];
				needsDownload = (modificationDate.timeIntervalSinceNow > kTIXboxLiveEngineImageCacheTime);
				
#if TARGET_OS_IPHONE
				image = [[[UIImage alloc] initWithContentsOfFile:filePath] autorelease];
#else
				image = [[[NSImage alloc] initWithContentsOfFile:filePath] autorelease];
#endif
				[self storeImageInMemoryCache:image key:cacheKey];
			}
			
			if (needsDownload) [self downloadImageAtURL:URL key:cacheKey completionBlock:block];
		}
	}
	
	if (image && block) block(image, URL);
	
	return !needsDownload;
}

- (void)removeImageForURL:(NSURL *)URL {
	
	if (URL){
		NSString * cacheKey = [self cacheKeyForURL:URL];
		[memoryCache removeObjectForKey:cacheKey];
		[[NSFileManager defaultManager] removeItemAtPath:[self filePathForKey:cacheKey] error:NULL];
	}
}

- (void)emptyDiskCache {
	
	if (!emptyingDiskCache){
		dispatch_async(ioQueue, ^{
			
			emptyingDiskCache = YES;
			
			NSString * directoryPath = [[self filePathForKey:@""] stringByDeletingLastPathComponent];
			NSFileManager * fileManager = [[NSFileManager alloc] init];
			NSDirectoryEnumerator * enumerator = [fileManager enumeratorAtPath:directoryPath];
			NSString * file = nil;
			
			while ((file = [enumerator nextObject])){
				if ([file contains:@".xboximage"]) [[NSFileManager defaultManager] removeItemAtPath:[directoryPath stringByAppendingFormat:@"/%@", file] error:NULL];
			}
			
			emptyingDiskCache = NO;
			[fileManager release];
		});
		
		[self emptyMemoryCache];
	}
}

- (void)emptyMemoryCache {
	[memoryCache removeAllObjects];
}

#pragma mark - Private Helpers
- (NSString *)cacheKeyForURL:(NSURL *)URL {
	
	const char * str = URL.absoluteString.UTF8String;
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
}

- (NSString *)filePathForKey:(NSString *)key {
	return [cacheRootDirectory stringByAppendingFormat:@"%@.xboximage", key];
}

- (void)storeImageInMemoryCache:(id)image key:(NSString *)key {
	
	if (memoryCache.allKeys.count >= kTIXboxLiveEngineMaxImageCount) [memoryCache removeObjectForKey:[memoryCache.allKeys lastObject]];
	if (image && key) [memoryCache setObject:image forKey:key];
}

- (void)writeImageData:(NSData *)imageData image:(id)image toPathWithKey:(NSString *)key completion:(dispatch_block_t)completion {
	[self storeImageInMemoryCache:image key:key];
	
	dispatch_async(ioQueue, ^{
		[imageData writeToFile:[self filePathForKey:key] atomically:YES];
		if (completion) dispatch_async(dispatch_get_main_queue(), ^{completion();});
	});
}
					 
- (void)downloadImageAtURL:(NSURL *)URL key:(NSString *)key completionBlock:(TIXboxLiveEngineImageCacheCompletionBlock)block {
	
	NSURLRequest * request = [[NSURLRequest alloc] initWithURL:URL];
	TIXboxLiveEngineConnection * connection = [[TIXboxLiveEngineConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
	[request release];
	
	[connection setType:TIXboxLiveEngineConnectionTypeGetTileImage];
	[connection setCallback:block];
	
	NSDictionary * userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:key, kTIXboxLiveEngineConnectionCacheKeyKey,
							   URL, kTIXboxLiveEngineConnectionURLKey, nil];
	[connection setUserInfo:userInfo];
	[userInfo release];
	
	if (connection){
		NSMutableData * data = [[NSMutableData alloc] init];
		[returnDataDict setObject:data forKey:[NSValue valueWithPointer:connection]];
		[data release];
	}
	
	[connection start];
	[connection release];
}

#pragma mark - NSURLConnection Delegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[returnDataDict removeObjectForKey:[NSValue valueWithPointer:connection]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(NSMutableData *)[returnDataDict objectForKey:[NSValue valueWithPointer:connection]] appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[(NSMutableData *)[returnDataDict objectForKey:[NSValue valueWithPointer:connection]] setLength:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	TIXboxLiveEngineConnection * imageConnection = (TIXboxLiveEngineConnection *)connection;
	TIXboxLiveEngineImageCacheCompletionBlock completionBlock = (TIXboxLiveEngineImageCacheCompletionBlock)imageConnection.callback;
	
	NSData * returnData = [returnDataDict objectForKey:[NSValue valueWithPointer:connection]];
	NSString * cacheKey = [imageConnection.userInfo objectForKey:kTIXboxLiveEngineConnectionCacheKeyKey];
	NSURL * URL = [imageConnection.userInfo objectForKey:kTIXboxLiveEngineConnectionURLKey];
	
#if TARGET_OS_IPHONE
	UIImage * tileImage = [[UIImage alloc] initWithData:returnData];
#else
	NSImage * tileImage = [[NSImage alloc] initWithData:returnData];
#endif
	
	if (tileImage){
		
		CGFloat scale = tileImage.size.width / tileImage.size.height;
		if (scale < 0.74 && scale > 0.7){
			
			dispatch_async(processingQueue, ^{
				CGFloat xValue = tileImage.size.height / 8;
#if TARGET_OS_IPHONE
				UIImage * croppedImage = [tileImage imageCroppedToRect:(CGRect){{0, xValue}, {tileImage.size.width, tileImage.size.width}}];
				NSData * croppedData = UIImageJPEGRepresentation(croppedImage, 0.0);
#else
				NSImage * croppedImage = [tileImage imageCroppedToRect:(NSRect){{0, xValue}, {tileImage.size.width, tileImage.size.width}}];
				NSData * croppedData = NSImageJPEGRepresentation(croppedImage, 0.0);
#endif
				[self writeImageData:croppedData image:croppedImage toPathWithKey:cacheKey completion:^{
					if (completionBlock) completionBlock(croppedImage, URL);
				}];
			});
		}
		else
		{
			[self writeImageData:returnData image:tileImage toPathWithKey:cacheKey completion:^{
				if (completionBlock) completionBlock(tileImage, URL);
			}];
		}
	}
	
	[tileImage release];
	[returnDataDict removeObjectForKey:[NSValue valueWithPointer:connection]];
}

#pragma mark - Memory Management
- (void)dealloc {
	[returnDataDict release];
	[memoryCache release];
	dispatch_release(processingQueue);
	dispatch_release(ioQueue);
	[cacheRootDirectory release];
	[super dealloc];
}

#pragma mark - Singleton stuff
+ (TIXboxLiveEngineImageCache *)sharedCache {
	
	static TIXboxLiveEngineImageCache * shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{shared = [[self alloc] init];});
	
	return shared;
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (NSUInteger)retainCount {
	return NSUIntegerMax;
}

- (oneway void)release {}

- (id)autorelease {
	return self;
}

@end
