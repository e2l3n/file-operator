//
//  FileOperator.h
//
//  Created by Toma Popov on 1/23/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BIQFileOperator : NSObject

@property (nonatomic, readonly) NSOperationQueue *fileLoadQueue;

+ (instancetype)sharedInstance;

/*
 In case the operaion is image lookup, the method first searches asynchronously
 in the virtual image cache for an image with the specified url.
 If not found, then searches in the defined local cache dir. A completion block is executed at the end.
 */
- (void)cachedDataForFileName:(NSString *)filename
                isImageLookup:(BOOL)isImageLookup
              completionQueue:(NSOperationQueue *)completionQueue
                   completion:(void (^)(NSData *result, NSError *error))completion;

/*
 Converts the URL to filename and acts like previous API method(above)
 */
- (void)cachedDataForURL:(NSURL *)URL
           isImageLookup:(BOOL)isImageLookup
         completionQueue:(NSOperationQueue *)completionQueue
              completion:(void (^)(NSData *result, NSError *error))completion;


/*
 Caches asynchronously image files and adds them to a virtual image cache in case isImageOp is YES.
 The cache gets cleaned when a memory warning is raised.
 Completion block is passed at the end.
 */
- (void)storeData:(NSData *)data
        isImageOp:(BOOL)isImageOp
         fileName:(NSString *)filename
  completionQueue:(NSOperationQueue *)completionQueue
       completion:(void (^)(NSError *error))completion;

/*
 Caches asynchronously image files and adds them to a virtual image cache in case isImageOp is YES.
 The cache gets cleaned when a memory warning is raised.
 Completion block is passed at the end.
 */
- (void)storeData:(NSData *)data
        isImageOp:(BOOL)isImageOp
         URL:(NSURL *)URL
  completionQueue:(NSOperationQueue *)completionQueue
       completion:(void (^)(NSError *error))completion;

/*
 Deletes asynchronously specific files corresponding to core data entities. Completion block is passed at the end.
 */
- (void)removeCachedDataForEntities:(NSArray *)entities
                        ofClassType:(Class)classType
                    completionQueue:(NSOperationQueue *)completionQueue
                         completion:(void (^)(NSError *error))completion;

/*
 Deletes asynchronously specific file. Completion block is passed at the end.
 */
- (void)removeCachedDataForFilename:(NSString *)filename
                    completionQueue:(NSOperationQueue *)completionQueue
                         completion:(void (^)(NSError *error))completion;

/*
 Deletes asynchronously all cached files.
 The manager itself has a private functinality that performs general clean up once every week.
 */
- (void)performAllFilesCleanUp;

//get a file path for specific file
- (NSString *)localFilePathForFilename:(NSString *)filename;
- (NSString *)localFilePathForURL:(NSURL *)url;

//add data to image cache
- (void)addDataToImageCache:(NSData *)data forFilename:(NSString *)filename;

@end
