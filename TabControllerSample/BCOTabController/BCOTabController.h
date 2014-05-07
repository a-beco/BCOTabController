//
//  BCOTabController.h
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/12.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCOTabColor.h"

// トップにタブを配置するコンテナビューコントローラ。
// タブのタイトルはViewControllerのtitleプロパティが反映される。
@protocol BCOTabControllerDelegate;
@interface BCOTabController : UIViewController

@property (nonatomic, weak) id<BCOTabControllerDelegate> delegate;

// array of UIViewController or its subclasses.
@property (nonatomic, copy) NSArray *viewControllers;

// array of BCOTabColor. セットしなければデフォルト.
@property (nonatomic, copy) NSArray *tabColors;

// 現在表示中のViewController
@property (nonatomic, readonly) UIViewController *selectedViewController;

// 現在選択中のタブのインデックス
@property (nonatomic) NSUInteger selectedIndex;

// 横スワイプでビューを移動するか
@property (nonatomic, getter = isHorizontalSwipeEnabled) BOOL horizontalSwipeEnabled;

@end


@protocol BCOTabControllerDelegate <NSObject>

// タブを移動開始した時に呼ばれる
- (void)tabControllerDidStartMoving:(BCOTabController *)tabController;

// タブを移動した時に呼ばれる
- (void)tabController:(BCOTabController *)tabController
        didMoveToIndex:(NSUInteger)index;

// タブ移動をキャンセルした時に呼ばれる
- (void)tabControllerDidCancelMoving:(BCOTabController *)tabController;

@end


@interface UIViewController (BCOTabControllerAddition)

@property (nonatomic, readonly) BCOTabController *tabController;

@end

