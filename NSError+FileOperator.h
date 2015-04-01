//
//  NSError+FileOperator.h
//
//  Created by Toma Popov on 1/22/15.
//  Copyright (c) 2015 . All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ErrorCodeFileOperation = 1002
} ErrorCode;

extern NSString * const kErrorDomain;

@interface NSError (FileOperator)

+ (NSError *)errorWithCode:(ErrorCode)code description:(NSString *)description;

@end
