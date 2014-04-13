//
//  BCOTabColor.h
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BCOTabColor : NSObject <NSCopying>

@property (nonatomic, readonly) UIColor *backgroundColor;
@property (nonatomic, readonly) UIColor *textColor;
@property (nonatomic, readonly) UIColor *highlightedBackgroundColor;
@property (nonatomic, readonly) UIColor *highlightedTextColor;

+ (BCOTabColor *)tabColorWithBackgroundColor:(UIColor *)backgroundColor
                                   textColor:(UIColor *)textColor
                  highlightedBackgroundColor:(UIColor *)highlightedBackgroundColor
                        highlightedTextColor:(UIColor *)highlightedTextColor;

@end