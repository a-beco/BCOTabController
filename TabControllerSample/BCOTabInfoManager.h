//
//  BCOTabInfoManager.h
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BCOTabColor.h"

@class BCOTabColor;
@interface BCOTabInfoManager : NSObject

+ (BCOTabInfoManager *)sharedManager;

- (NSArray *)allTitles;
- (NSString *)titleAtIndex:(NSUInteger)index;

- (NSArray *)allColors;
- (BCOTabColor *)colorAtIndex:(NSUInteger)index;

@end
