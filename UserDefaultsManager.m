//
//  UserDefaultsManager.m
//
//  Created by Toma Popov on 1/23/15.
//  Copyright (c) 2015 . All rights reserved.
//

#import "UserDefaultsManager.h"

NSString * const kTimeOfLastLocalFileCleanUpKey = @"kTimeOfLastLocalFileCleanUpKey";

@implementation UserDefaultsManager

+ (id)sharedManager {
    static UserDefaultsManager *userDefaultsManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userDefaultsManager = [[UserDefaultsManager alloc] init];
    });
    
    return userDefaultsManager;
}

- (NSDate *)timeOfLastLocalFileCleanUp {
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    return [userDefaults objectForKey:kTimeOfLastLocalFileCleanUpKey];
}

- (void)setTimeOfLastLocalFileCleanUp:(NSDate *)date {
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    if (![date isKindOfClass:NSDate.class]) {
        [userDefaults removeObjectForKey:kTimeOfLastLocalFileCleanUpKey];
    } else {
        [userDefaults setObject:date forKey:kTimeOfLastLocalFileCleanUpKey];
    }
    
    [userDefaults synchronize];
}

@end
