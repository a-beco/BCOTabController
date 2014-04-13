//
//  BCOTabColor.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOTabColor.h"

@interface BCOTabColor ()

@property (nonatomic, readwrite) UIColor *backgroundColor;
@property (nonatomic, readwrite) UIColor *textColor;
@property (nonatomic, readwrite) UIColor *highlightedBackgroundColor;
@property (nonatomic, readwrite) UIColor *highlightedTextColor;

@end

@implementation BCOTabColor

+ (BCOTabColor *)tabColorWithBackgroundColor:(UIColor *)backgroundColor
                                   textColor:(UIColor *)textColor
                  highlightedBackgroundColor:(UIColor *)highlightedBackgroundColor
                        highlightedTextColor:(UIColor *)highlightedTextColor
{
    BCOTabColor *tabColor = [[BCOTabColor alloc] init];
    tabColor.backgroundColor                = backgroundColor;
    tabColor.textColor                      = textColor;
    tabColor.highlightedBackgroundColor     = highlightedBackgroundColor;
    tabColor.highlightedTextColor           = highlightedTextColor;
    return tabColor;
}

- (id)copyWithZone:(NSZone *)zone
{
    BCOTabColor *copyTabColor = [[BCOTabColor alloc] init];
    copyTabColor.backgroundColor            = self.backgroundColor;
    copyTabColor.textColor                  = self.textColor;
    copyTabColor.highlightedBackgroundColor = self.highlightedBackgroundColor;
    copyTabColor.highlightedTextColor       = self.highlightedTextColor;
    return copyTabColor;
}

@end
