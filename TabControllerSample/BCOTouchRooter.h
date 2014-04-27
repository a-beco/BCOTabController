//
//  BCOTouchRooter.h
//  BCOTouchRooter
//
//  Created by 阿部耕平 on 2014/04/22.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BCOTouchReceiver;
@class BCOTouchFilter;

// タッチイベントをルーティングするクラス。
//
// addReceiver:で追加されたレシーバオブジェクトに対し、タッチイベントを渡す。
// filterForReceiver:で取得できるフィルタオブジェクトにblockMaskで、
// 通知するか否かの条件を設定できる。
//
// Note: スレッドセーフではありません。
@interface BCOTouchRooter : NSObject

+ (BCOTouchRooter *)sharedRooter;

// レシーバオブジェクトを通知リストに追加する。重複は無視。
- (void)addReceiver:(id<BCOTouchReceiver>)receiver;

// レシーバオブジェクトを通知リストから削除する。
- (void)removeReceiver:(id<BCOTouchReceiver>)receiver;

@end

@interface BCOTouchRooter (BCOTouchRooterFiltering)

// 通常のタッチイベントに対するフィルタを取得する。
- (BCOTouchFilter *)defaultFilter;

// 引数で指定したレシーバと紐づくフィルタを取得する。
- (BCOTouchFilter *)filterForReceiver:(id<BCOTouchReceiver>)receiver;

@end

// BCOTouchRooterに-addReceiver:した上で、このプロトコルを実装することで
// タッチイベントの通知を受け取ることができます。
@protocol BCOTouchReceiver <NSObject>

@optional
- (void)didReceiveTouchesBegan:(NSSet *)touches event:(UIEvent *)event;
- (void)didReceiveTouchesMoved:(NSSet *)touches event:(UIEvent *)event;
- (void)didReceiveTouchesEnded:(NSSet *)touches event:(UIEvent *)event;
- (void)didReceiveTouchesCancelled:(NSSet *)touches event:(UIEvent *)event;

@end


//「通知をブロックする条件」を指定する。条件に合致していれば通知しない。
// BCOTouchFilterMaskOutOfViewBounds: ビューの矩形の中でなければブロック。UIView/UIViewController。
// BCOTouchFilterMaskHitView: ヒットビューであればブロック。UIView/UIViewController。
// BCOTouchFilterMaskNotHitView: ヒットビューでなければブロック。UIView/UIViewController。
// BCOTouchFilterMaskHitViewIsNotSubview: ヒットビューが子孫のビューでなければブロック。UIView/UIViewController。
// BCOTouchFilterMaskMultipleTouch: ２つ以上の通知が来たときは２つめ以降をブロック。
typedef NS_OPTIONS(NSUInteger, BCOTouchFilterBlockMask) {
    BCOTouchFilterMaskOutOfViewBounds           = 1 << 0,
    BCOTouchFilterMaskHitView                   = 1 << 1,
    BCOTouchFilterMaskNotHitView                = 1 << 2,
    BCOTouchFilterMaskHitViewIsNotSubview       = 1 << 3,
    BCOTouchFilterMaskMultipleTouch             = 1 << 4,
};


// BCOTouchRooterの通知/非通知の切り替えや通知条件の設定。
// BCOTouchRooterに追加したReceiverと１対１で紐づく。
// initで生成せず、BCOTouchRooterの+filterForReceiver:などを使うこと。
@interface BCOTouchFilter : NSObject 

// タッチイベントの通知を全てブロックするかどうか
@property (nonatomic, getter=isBlocked) BOOL blocked;

// タッチイベントの通知をブロックする条件を設定。デフォルトのフィルタでは無視される。
@property (nonatomic) BCOTouchFilterBlockMask blockMask;

@end
