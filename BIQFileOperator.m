//
//  FileOperator.m
//
//  Created by Toma Popov on 1/23/15.
//  Copyright (c) 2015 . All rights reserved.
//

#import "FileOperator.h"
#import <UIKit/UIKit.h>
#import "NSError+FileOperator.h"
#import "UserDefaultsManager.h"

const NSUInteger kOneWeekInSeconds =  60 * 60 * 24 * 7;

@interface FileOperator ()

@property (strong, nonatomic) NSOperationQueue *fileLoadQueue;
@property (strong, nonatomic) NSString *cachesDirectoryPath;
@property (strong, nonatomic) NSCache *imageCache;

@end

@implementation FileOperator

static FileOperator *sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.fileLoadQueue = [NSOperationQueue new];
        self.cachesDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        
        self.imageCache = [NSCache new];
        self.imageCache.countLimit = 10; //not final value
        [self performAllFilesCleanUp];
        [self setupDirectories];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMemoryWarningNotification:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    
    return self;
}

- (NSString *)localFileNameForRemoteURLString:(NSURL *)remoteURL {
    if (![remoteURL isKindOfClass:NSURL.class]) {
        return nil;
    }
    
    NSString *localFileName = [NSString stringWithUTF8String:remoteURL.fileSystemRepresentation];
    return [localFileName stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
}

#pragma mark - Public interface

- (void)cachedDataForURL:(NSURL *)URL
           isImageLookup:(BOOL)isImageLookup
         completionQueue:(NSOperationQueue *)completionQueue
              completion:(void (^)(NSData *result, NSError *error))completion {
    [self cachedDataForFileName:[self localFileNameForRemoteURLString:URL]
                  isImageLookup:isImageLookup
                completionQueue:completionQueue
                     completion:completion];
}

- (void)cachedDataForFileName:(NSString *)filename
                isImageLookup:(BOOL)isImageLookup
              completionQueue:(NSOperationQueue *)completionQueue
                   completion:(void (^)(NSData *result, NSError *error))completion {
    if (!filename.length) {
        NSError *err = [NSError errorWithCode:ErrorCodeFileOperation description:@"Missing URL string."];
        if (completion) {
            [self operationQueue:completionQueue performBlock:^{
                completion(nil, err);
            }];
        }
        
        return;
    }
    
    NSBlockOperation *fileLookOp = [NSBlockOperation new];
    [fileLookOp addExecutionBlock:^{
        NSData *cachedData = [self fileForFilePath:[self localFilePathForFilename:filename]
                                     isImageLookup:isImageLookup];
        
        if (completion) {
            if (cachedData) {
                [self operationQueue:completionQueue performBlock:^{
                    completion(cachedData, nil);
                }];
            } else {
                NSError *error = [NSError errorWithCode:ErrorCodeFileOperation description:@"No cached file found."];
                [self operationQueue:completionQueue performBlock:^{
                    completion(nil, error);
                }];
            }
        }
    }];
    
    [self.fileLoadQueue addOperation:fileLookOp];
}

- (void)storeData:(NSData *)data
        isImageOp:(BOOL)isImageOp
         fileName:(NSString *)filename
  completionQueue:(NSOperationQueue *)completionQueue
       completion:(void (^)(NSError *error))completion {
    if (!data || !filename) {
        NSError *err = [NSError errorWithCode:ErrorCodeFileOperation description:@"Missing data or URL string."];
        if (completion) {
            [self operationQueue:completionQueue performBlock:^{
                completion(err);
            }];
        }
        
        return;
    }
    
    NSBlockOperation *fileLookOp = [NSBlockOperation new];
    [fileLookOp addExecutionBlock:^{
        NSString *filePath = [self localFilePathForFilename:filename];
        if (![[NSFileManager defaultManager] createFileAtPath:filePath contents:data attributes:nil]) {
            NSError *err = [NSError errorWithCode:ErrorCodeFileOperation description:@"Saving failed."];
            if (completion) {
                [self operationQueue:completionQueue performBlock:^{
                    completion(err);
                }];
            }
            
            return;
        }
        
        if (isImageOp) {
            [self addDataToImageCache:data forFilename:filename];
        }
        
        if (completion) {
            [self operationQueue:completionQueue performBlock:^{
                completion(nil);
            }];
        }
    }];
    
    [self.fileLoadQueue addOperation:fileLookOp];
}

- (void)storeData:(NSData *)data
        isImageOp:(BOOL)isImageOp
              URL:(NSURL *)URL
  completionQueue:(NSOperationQueue *)completionQueue
       completion:(void (^)(NSError *error))completion {
    [self storeData:data
          isImageOp:isImageOp
           fileName:[self localFileNameForRemoteURLString:URL]
    completionQueue:completionQueue
         completion:completion];
    
}

- (void)removeCachedDataForEntities:(NSArray *)entities
                        ofClassType:(Class)classType
                    completionQueue:(NSOperationQueue *)completionQueue
                         completion:(void (^)(NSError *error))completion {}

- (void)removeCachedDataForFilename:(NSString *)filename
                    completionQueue:(NSOperationQueue *)completionQueue
                         completion:(void (^)(NSError *error))completion {
    NSBlockOperation *fileLookOp = [NSBlockOperation new];
    [fileLookOp addExecutionBlock:^{
        NSString *filePath = [self localFilePathForFilename:filename];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *fileOpErr;
        BOOL success = [fileManager removeItemAtPath:filePath error:&fileOpErr];
        if (!success) {
            //failure
        }
        
        if (completion) {
            [self operationQueue:completionQueue performBlock:^{
                completion(nil);
            }];
        }
    }];
    
    [self.fileLoadQueue addOperation:fileLookOp];
}

- (void)performAllFilesCleanUp {
    if (![UserDefaultsManager.sharedManager timeOfLastLocalFileCleanUp]) {
        [UserDefaultsManager.sharedManager setTimeOfLastLocalFileCleanUp:NSDate.date];
    } else if ([NSDate.date timeIntervalSinceDate:[UserDefaultsManager.sharedManager timeOfLastLocalFileCleanUp]] >= kOneWeekInSeconds) {
        if ([[NSFileManager defaultManager] removeItemAtPath:self.cachesDirectoryPath error:nil]) {
            [UserDefaultsManager.sharedManager setTimeOfLastLocalFileCleanUp:NSDate.date];
        }
    }
}

#pragma mark - Local Image Retrieval

- (NSData *)fileForFilePath:(NSString *)filePath isImageLookup:(BOOL)imageLookup {
    NSData *result = nil;
    if (filePath) {
        //check in virtual cache
        if (imageLookup) {
            result = [self.imageCache objectForKey:[filePath lastPathComponent]];
        }
        
        if (!result) {
            //check in local storage
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                result = [NSData dataWithContentsOfFile:filePath];
                [self addDataToImageCache:result forFilename:[filePath lastPathComponent]];
            }
        }
    }
    
    return result;
}

#pragma mark - Image Local Path Utilities

- (NSString *)localFilePathForURL:(NSURL *)url {
    return [self localFilePathForFilename:[self localFileNameForRemoteURLString:url]];
}

- (NSString *)folderInCachesWithName:(NSString *)folderName {
    NSString *result = [self.cachesDirectoryPath stringByAppendingPathComponent:folderName];
    return result;
}

- (NSString *)cachesDirectoryPath {
    return [self folderInCachesWithName:@"cached_files"];
}

- (NSString *)localFilePathForFilename:(NSString *)filename {
    return filename ? [self.cachesDirectoryPath stringByAppendingPathComponent:filename] : nil;
}

- (void)addDataToImageCache:(NSData *)data forFilename:(NSString *)filename {
    //add to virutal cache
    [self.imageCache setObject:data forKey:filename];
}

#pragma mark - Directory Setup

- (void)setupDirectories {
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if (![manager fileExistsAtPath:self.cachesDirectoryPath]) {
        [manager createDirectoryAtPath:self.cachesDirectoryPath
           withIntermediateDirectories:YES
                            attributes:nil error:NULL];
    }
}

#pragma mark - System notifications

- (void)handleMemoryWarningNotification:(NSNotification *)aNotification {
    [self.imageCache removeAllObjects];
}

#pragma mark - Dispatch on queue

- (void)operationQueue:(NSOperationQueue *)operationQueue performBlock:(void (^)(void))block {
    if (block) {
        if (operationQueue && operationQueue != NSOperationQueue.currentQueue) {
            [operationQueue addOperationWithBlock:block];
        }
        else {
            block();
        }
    }
}

@end