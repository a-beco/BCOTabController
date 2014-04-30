//
//  UIView+UIViewDescendantViews.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/05/01.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "UIView+UIViewDescendantViews.h"

@implementation UIView (UIViewDescendantViews)

- (NSArray *)allDescendantViews
{
    NSMutableArray *subviewsBuf = @[].mutableCopy;
    for (UIView *subview in self.subviews) {
        [subviewsBuf addObject:subview];
        
        if ([subview.subviews count] != 0) {
            // 再帰的なメソッド呼び出し
            NSArray *subsubviews = [subview allDescendantViews];
            [subviewsBuf addObjectsFromArray:subsubviews];
        }
    }
    return [subviewsBuf copy];
}

@end
