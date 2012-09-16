//
//  TIXboxLiveEngineImageCache.h
//  Friendz
//
//  Created by Tom Irving on 13/09/2012.
//  Copyright (c) 2012 Tom Irving. All rights reserved.
//

#if TARGET_OS_IPHONE
typedef void (^TIXboxLiveEngineImageCacheCompletionBlock)(UIImage * image, NSURL * URL);
#else
typedef void (^TIXboxLiveEngineImageCacheCompletionBlock)(NSImage * image, NSURL * URL);
#endif

@interface TIXboxLiveEngineImageCache : NSObject {
	
	NSMutableDictionary	* returnDataDict;
	NSMutableDictionary * memoryCache;
	
	dispatch_queue_t processingQueue;
	dispatch_queue_t ioQueue;
	BOOL emptyingDiskCache;
	
	NSString * cacheRootDirectory;
}

@property (nonatomic, copy) NSString * cacheRootDirectory;

+ (TIXboxLiveEngineImageCache *)sharedCache;

- (BOOL)getImageForURL:(NSURL *)URL completion:(TIXboxLiveEngineImageCacheCompletionBlock)block;
- (void)removeImageForURL:(NSURL *)URL;

- (void)emptyDiskCache;
- (void)emptyMemoryCache;

@end