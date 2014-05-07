//
//  UIView+UIViewDescendantViews.h
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/05/01.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (UIViewDescendantViews)

// 全ての子孫ビューを再帰的に取得し、NSArrayで返す。
// 存在しなければ空の配列を返す。
- (NSArray *)allDescendantViews;

@end
