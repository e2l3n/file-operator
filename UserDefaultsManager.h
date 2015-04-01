//
//  UserDefaultsManager.h
//
//  Created by Toma Popov on 1/23/15.
//  Copyright (c) 2015 . All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserDefaultsManager : NSObject

+ (instancetype)sharedManager;

@property (weak, nonatomic) NSDate *timeOfLastLocalFileCleanUp;

@end
