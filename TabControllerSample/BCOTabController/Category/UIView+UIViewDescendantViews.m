//
//  UIView+UIViewDescendantViews.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/05/01.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "UIView+UIViewDescendantViews.h"

@implementation UIView (UIViewDescendantViews)

// 引数view以下の全ての子ビュー、孫ビュー、ひ孫ビュー...を再帰的に取得し、NSArrayで返す。
- (NSArray *)allDescendantViews
{
    NSMutableArray *subviewsBuf = @[].mutableCopy;
    for (UIView *subview in self.subviews) {
        [subviewsBuf addObject:subview];
        
        if ([subview.subviews count] != 0) {
            // 再帰的なメソッド呼び出し
            NSArray *subsubviews = [self p_allDescendantViewsBelowView:subview];
            [subviewsBuf addObjectsFromArray:subsubviews];
        }
    }
    return [subviewsBuf copy];
}

@end
