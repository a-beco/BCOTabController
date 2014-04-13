//
//  BCOTabListView.h
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BCOTabListViewDelegate;
@interface BCOTabListView : UIView

@property (nonatomic, weak) id<BCOTabListViewDelegate> delegate;

@property (nonatomic, copy) NSArray *titles;    // array of NSString
@property (nonatomic, copy) NSArray *tabColors; // array of BCOTabColor
@property (nonatomic) NSUInteger selectedIndex;

@end

@protocol BCOTabListViewDelegate <NSObject>

- (void)tabListView:(BCOTabListView *)tabListView didTapIndex:(NSUInteger)selectedIndex;

@end