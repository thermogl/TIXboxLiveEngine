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

@implementation TIXboxLiveEngineImageCache {
	NSMutableDictionary	* _returnDataDict;
	NSMutableDictionary * _memoryCache;
	
	dispatch_queue_t _processingQueue;
	dispatch_queue_t _ioQueue;
	BOOL _emptyingDiskCache;
}
@synthesize cacheRootDirectory = _cacheRootDirectory;
@synthesize cropsGameBoxArt = _cropsGameBoxArt;

#pragma mark - Instance Methods
- (id)init {
	
	if ((self = [super init])){
		_memoryCache = [[NSMutableDictionary alloc] init];
		_returnDataDict = [[NSMutableDictionary alloc] init];
		_processingQueue = dispatch_queue_create("com.TIXboxLiveEngineImageCache.ProcessingQueue", NULL);
		_ioQueue = dispatch_queue_create("com.TIXboxLiveEngineImageCache.IOQueue", NULL);
		_emptyingDiskCache = NO;
		_cropsGameBoxArt = YES;
#if TARGET_OS_IPHONE
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emptyMemoryCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
	}
	
	return self;
}

- (BOOL)getImageForURL:(NSURL *)URL completion:(TIXboxLiveEngineImageCacheCompletionBlock)block {
	
	id image = nil;
	BOOL needsDownload = YES;
	
	if (URL && !_emptyingDiskCache){
		
		needsDownload = NO;
		NSString * cacheKey = [self cacheKeyForURL:URL];
		NSString * filePath = [self filePathForKey:cacheKey];
		
		if (!(image = [_memoryCache objectForKey:cacheKey])){
			needsDownload = YES;
			
			NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
			if (attributes){
				NSDate * modificationDate = [attributes objectForKey:NSFileModificationDate];
				needsDownload = (modificationDate.timeIntervalSinceNow > kTIXboxLiveEngineImageCacheTime);
#if TARGET_OS_IPHONE
				image = [UIImage imageWithContentsOfFile:filePath];
#else
				image = [[NSImage alloc] initWithContentsOfFile:filePath];
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
		[_memoryCache removeObjectForKey:cacheKey];
		[[NSFileManager defaultManager] removeItemAtPath:[self filePathForKey:cacheKey] error:NULL];
	}
}

- (void)emptyDiskCache {
	
	if (!_emptyingDiskCache){
		dispatch_async(_ioQueue, ^{
			
			_emptyingDiskCache = YES;
			
			NSString * directoryPath = [[self filePathForKey:@""] stringByDeletingLastPathComponent];
			NSFileManager * fileManager = [[NSFileManager alloc] init];
			NSDirectoryEnumerator * enumerator = [fileManager enumeratorAtPath:directoryPath];
			NSString * file = nil;
			
			while ((file = [enumerator nextObject])){
				if ([file contains:@".xboximage"]) [[NSFileManager defaultManager] removeItemAtPath:[directoryPath stringByAppendingFormat:@"/%@", file] error:NULL];
			}
			
			_emptyingDiskCache = NO;
		});
		
		[self emptyMemoryCache];
	}
}

- (void)emptyMemoryCache {
	[_memoryCache removeAllObjects];
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
	return [_cacheRootDirectory stringByAppendingFormat:@"%@.xboximage", key];
}

- (void)storeImageInMemoryCache:(id)image key:(NSString *)key {
	
	if (_memoryCache.allKeys.count >= kTIXboxLiveEngineMaxImageCount) [_memoryCache removeObjectForKey:[_memoryCache.allKeys lastObject]];
	if (image && key) [_memoryCache setObject:image forKey:key];
}

- (void)writeImageData:(NSData *)imageData image:(id)image toPathWithKey:(NSString *)key completion:(dispatch_block_t)completion {
	[self storeImageInMemoryCache:image key:key];
	
	dispatch_async(_ioQueue, ^{
		[imageData writeToFile:[self filePathForKey:key] atomically:YES];
		if (completion) dispatch_async(dispatch_get_main_queue(), ^{completion();});
	});
}
					 
- (void)downloadImageAtURL:(NSURL *)URL key:(NSString *)key completionBlock:(TIXboxLiveEngineImageCacheCompletionBlock)block {
	
	NSURLRequest * request = [NSURLRequest requestWithURL:URL];
	TIXboxLiveEngineConnection * connection = [[TIXboxLiveEngineConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
	[connection setType:TIXboxLiveEngineConnectionTypeGetTileImage];
	[connection setCallback:block];
	[connection setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:key, kTIXboxLiveEngineConnectionCacheKeyKey,
							 URL, kTIXboxLiveEngineConnectionURLKey, nil]];
	
	if (connection) [_returnDataDict setObject:[NSMutableData data] forKey:[NSValue valueWithNonretainedObject:connection]];
	[connection start];
}

#pragma mark - NSURLConnection Delegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[_returnDataDict removeObjectForKey:[NSValue valueWithNonretainedObject:connection]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[(NSMutableData *)[_returnDataDict objectForKey:[NSValue valueWithNonretainedObject:connection]] appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[(NSMutableData *)[_returnDataDict objectForKey:[NSValue valueWithNonretainedObject:connection]] setLength:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	TIXboxLiveEngineConnection * imageConnection = (TIXboxLiveEngineConnection *)connection;
	TIXboxLiveEngineImageCacheCompletionBlock completionBlock = (TIXboxLiveEngineImageCacheCompletionBlock)imageConnection.callback;
	
	NSData * returnData = [_returnDataDict objectForKey:[NSValue valueWithNonretainedObject:connection]];
	NSString * cacheKey = [imageConnection.userInfo objectForKey:kTIXboxLiveEngineConnectionCacheKeyKey];
	NSURL * URL = [imageConnection.userInfo objectForKey:kTIXboxLiveEngineConnectionURLKey];
	
#if TARGET_OS_IPHONE
	UIImage * tileImage = [UIImage imageWithData:returnData];
#else
	NSImage * tileImage = [[NSImage alloc] initWithData:returnData];
#endif
	
	if (tileImage){
		
		CGFloat scale = tileImage.size.width / tileImage.size.height;
		if (_cropsGameBoxArt && scale < 0.74 && scale > 0.7){
			
			dispatch_async(_processingQueue, ^{
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
	
	[_returnDataDict removeObjectForKey:[NSValue valueWithNonretainedObject:connection]];
}

#pragma mark - Singleton stuff
+ (TIXboxLiveEngineImageCache *)sharedCache {
	
	static TIXboxLiveEngineImageCache * shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{shared = [[self alloc] init];});
	
	return shared;
}

@end
