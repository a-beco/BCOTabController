//
//  BCOTabListView.h
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import <UIKit/UIKit.h>

// BCOTabControllerのトップに配置するタブを並べたビュー。
// UIScrollViewの中に多数のBCOTabItemを並べる。
// タブをタップすると選択中になり、そのタブが可能な限りビューの中心にくるようスクロールする。
@protocol BCOTabListViewDelegate;
@interface BCOTabListView : UIView

@property (nonatomic, weak) id<BCOTabListViewDelegate> delegate;

// 初めてtitlesをセットするときか、titlesの数が変わったときのみ全てのタブを生成しなおす。
// それ以外の場合は文字のみを更新する。
@property (nonatomic, copy) NSArray *titles;    // array of NSString

// 指定しなければデフォルトカラーが選択され、タブの数より多く指定すれば単に無視される。
@property (nonatomic, copy) NSArray *tabColors; // array of BCOTabColor

// 現在選択中のタブのインデックス。変更すると位置を移動する。
// 選択中のタブが可能な限りビューの中心に表示されるようスクロールする。
@property (nonatomic) NSUInteger selectedIndex;

@end


@protocol BCOTabListViewDelegate <NSObject>

// タブがタップされた時に呼ばれる。
- (void)tabListView:(BCOTabListView *)tabListView didTapIndex:(NSUInteger)selectedIndex;

@end