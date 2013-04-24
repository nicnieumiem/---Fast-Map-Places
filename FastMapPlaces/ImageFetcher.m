//
//  ImageFetcher.m
//  FastMapPlaces
//
//  Created by nicnieumiem.pl on 4/20/13.
//
//

#import "ImageFetcher.h"
#import "FlickrFetcher.h"

#define FILE_SIZE_KEY @"file_size"
#define FILE_ID_KEY @"file_key"

#define MAX_CACHE_SIZE 10485760

@interface ImageFetcher ()

@property (assign) BOOL cacheInitialized;
@property (strong, nonatomic) NSURL *diskCachePath;
@property (strong, nonatomic) dispatch_queue_t imageQ;
@property (strong, nonatomic) dispatch_queue_t diskQ;
@property NSMutableArray *cachedImageFiles;
@property (assign) int currentCacheSize;

@end

@implementation ImageFetcher

+(ImageFetcher *)sharedInstance
{
    static dispatch_once_t  once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

-(id) init {
    if((self = [super init])) {
        _cachedImageFiles = NSMutableArray.new;
        _imageQ = dispatch_queue_create("Image fetching queue", DISPATCH_QUEUE_SERIAL);
        _diskQ = dispatch_queue_create("Disk operations q dueue", DISPATCH_QUEUE_SERIAL);
        NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
        _diskCachePath = [paths lastObject];
        _currentCacheSize = 0;
    }
    return self;
}

-(void)updateCacheInfoWithPath:(NSString *)path andSize:(NSInteger)size {
    NSDictionary *fileEntry = [NSDictionary dictionaryWithObjectsAndKeys:path,FILE_ID_KEY,[NSNumber numberWithInteger:size], FILE_SIZE_KEY, nil];
    [self.cachedImageFiles insertObject:fileEntry atIndex:0];
    self.currentCacheSize += size;
}

-(void) initCache {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *cachedFiles = [fileManager contentsOfDirectoryAtURL:self.diskCachePath includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLCreationDateKey,nil] options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    if(cachedFiles != nil && [cachedFiles count]) {
        // cachedFiles - sort by creation date
        NSArray *cachedFilesSortedByDate = [cachedFiles sortedArrayUsingComparator:^NSComparisonResult(id obj1,id obj2) {
            NSDate *cDate1 = nil;
            NSDate *cDate2 = nil;
            if([(NSURL*)obj1 getResourceValue:&cDate1 forKey:NSURLCreationDateKey error:nil] &&
               [(NSURL*)obj2 getResourceValue:&cDate2 forKey:NSURLCreationDateKey error:nil]) {
                if([cDate1 timeIntervalSince1970] < [cDate2 timeIntervalSince1970]) {
                    return (NSComparisonResult)NSOrderedAscending;
                } else {
                    return (NSComparisonResult)NSOrderedDescending;
                }
            }
            // error - return default value
            else return (NSComparisonResult)NSOrderedSame;
        }];
        for(NSURL *url in cachedFilesSortedByDate) {
            NSDictionary *attrs = [fileManager attributesOfItemAtPath:[url path] error:nil];
            [self updateCacheInfoWithPath:[url path] andSize:[attrs fileSize]];
        }
    }
}

-(BOOL)resizeCacheToNewSize:(NSInteger)newSize {
    NSMutableIndexSet *filesToDelete = NSMutableIndexSet.new;
    NSInteger currSize = 0;
    NSUInteger currIndex = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for(NSDictionary *entry in self.cachedImageFiles) {
        NSInteger fileSize = [[entry objectForKey:FILE_SIZE_KEY] integerValue];
        if((currSize + fileSize) >= newSize) {
            [fileManager removeItemAtPath:[entry objectForKey:FILE_ID_KEY] error:NULL];
            if(![fileManager fileExistsAtPath:[entry objectForKey:FILE_ID_KEY]]) {
                self.currentCacheSize -= fileSize;
                [filesToDelete addIndex:currIndex];
            }
        }
        currSize += fileSize;
        currIndex++;
    }
    if([filesToDelete count]) {
        [self.cachedImageFiles removeObjectsAtIndexes:filesToDelete];
    }
    return YES;
}

-(void)storeImageInCache:(NSData *)imageData forKey:(NSString *)key {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *cachedImageURL = [self.diskCachePath URLByAppendingPathComponent:key];
    
    NSString *cachedImagePath = [cachedImageURL path];
    
    [fileManager createFileAtPath:cachedImagePath contents:imageData attributes:nil];
    [self updateCacheInfoWithPath:cachedImagePath andSize:[imageData length]];
}

-(void)cacheImageOnDisk:(NSData *)imageData usingKey:(NSString *)key {
    dispatch_async(self.diskQ, ^{
        if(!self.cacheInitialized) {
            [self initCache];
            self.cacheInitialized = YES;
        }
        
        BOOL cacheReady = YES;
        NSInteger dataSize = [imageData length];
        if(self.currentCacheSize + dataSize > MAX_CACHE_SIZE) {
            if(MAX_CACHE_SIZE > dataSize) {
                cacheReady = [self resizeCacheToNewSize:(MAX_CACHE_SIZE - dataSize)];
            }
            else cacheReady = NO;
        }
        if(cacheReady) [self storeImageInCache:imageData forKey:key];
    });
}

-(void)getImageUsingURL:(NSURL *)url completed:(ImageFetchingCompletedWithFinshedBlock)block {
    [self getImageUsingURL:url usingCacheForKey:nil completed:block];
}

-(void)getImageUsingURL:(NSURL *)url usingCacheForKey:(NSString *)key completed:(ImageFetchingCompletedWithFinshedBlock)completedBlock {
    if(!key) {
        //do not cache fetched image
        dispatch_async(self.imageQ, ^{
            NSData *data = [NSData dataWithContentsOfURL:url];
            dispatch_async(dispatch_get_main_queue(),^{
                UIImage *image = [UIImage imageWithData:data];
                completedBlock(image, data);
            });
        });
    }
    else {
        dispatch_async(self.diskQ, ^{
            NSURL *diskImageURL = [self.diskCachePath URLByAppendingPathComponent:key];
            // check if image cached
            NSData *imageData = [NSData dataWithContentsOfURL:diskImageURL];
            if(imageData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImage *image = [UIImage imageWithData:imageData];
                    completedBlock(image, nil);
                });
            }
            else {
                // fetch image from flickr
                [self getImageUsingURL:url completed:^(UIImage *blockImage, NSData *blockImageData){
                    // we are curently in the main queue
                    // display image
                    completedBlock(blockImage, nil);
                    [self cacheImageOnDisk:blockImageData usingKey:key];
                }];
            }
        });
    }
}

@end
