//
//  BCOPageController.h
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import <UIKit/UIKit.h>


// スライドでページを切り替えるビューコントローラ。
@protocol BCOPageControllerDelegate, BCOPageControllerDataSource;
@interface BCOPageController : UIViewController

@property (nonatomic, weak) id<BCOPageControllerDelegate> delegate;
@property (nonatomic, weak) id<BCOPageControllerDataSource> dataSource;

// ページのインデックスをセットするとページを移動
@property (nonatomic) NSUInteger selectedIndex;

@property (nonatomic, getter = isHorizontalSwipeEnabled) BOOL horizontalSwipeEnabled;

@end


@protocol BCOPageControllerDelegate <NSObject>

// ページが移動開始した時に呼ばれる
- (void)pageControllerDidStartMoving:(BCOPageController *)pageController;

// ページが移動した時に呼ばれる
- (void)pageController:(BCOPageController *)pageController
        didMoveToIndex:(NSUInteger)index;

// 移動をキャンセルした時に呼ばれる
- (void)pageControllerDidCancelMoving:(BCOPageController *)pageController;

@end

@protocol BCOPageControllerDataSource <NSObject>

// index番目のビューコントローラを返すようにする。
// nilを返せば移動しない。
- (UIViewController *)pageController:(BCOPageController *)pageController
                        pageForIndex:(NSUInteger)index;

@end