//
//  BCOTabItem.h
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BCOTabColor;
@protocol BCOTabItemDelegate;

@interface BCOTabItem : UIView

@property (nonatomic, weak) id<BCOTabItemDelegate> delegate;

@property (nonatomic, getter = isHighlighted) BOOL highlighted;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) BCOTabColor *color;

- (id)initWithFrame:(CGRect)frame
              title:(NSString *)title
              color:(BCOTabColor *)color;

@end


@protocol BCOTabItemDelegate <NSObject>

- (void)tabItemDidTap:(BCOTabItem *)tabItem;

@end