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
@interface BCOTabController : UIViewController

// array of UIViewController or its subclasses.
@property (nonatomic, copy) NSArray *viewControllers;

// array of BCOTabColor. セットしなければデフォルト.
@property (nonatomic, copy) NSArray *tabColors;

// 現在表示中のViewController
@property (nonatomic, readonly) UIViewController *selectedViewController;

// 現在選択中のタブのインデックス
@property (nonatomic) NSUInteger selectedIndex;

@end