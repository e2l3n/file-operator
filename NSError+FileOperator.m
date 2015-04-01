//
//  NSError+FileOperator.m
//
//  Created by Toma Popov on 1/22/15.
//  Copyright (c) 2015 . All rights reserved.
//

#import "NSError+FileOperator.h"

NSString * const kErrorDomain = @"com.xcode.fileOperation";

@implementation NSError (FileOperator)

+ (NSError *)errorWithCode:(ErrorCode)code description:(NSString *)description {
    return [NSError errorWithDomain:kErrorDomain code:code userInfo:[NSDictionary dictionaryWithObject:description
                                                                              forKey:NSLocalizedDescriptionKey]];
}

@end
