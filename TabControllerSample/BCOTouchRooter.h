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

// addReceiver:で追加されたレシーバオブジェクトに対し、
// 全てのタッチイベントを渡すクラス。
// タッチされていないオブジェクトにもタッチを通知できる。
// Note: 現状はスレッドセーフではありません。
@interface BCOTouchRooter : NSObject

+ (BCOTouchRooter *)sharedRooter;

- (void)addReceiver:(id<BCOTouchReceiver>)receiver;
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

//「通知をブロックする条件」を指定する。条件に合致していればブロック。
// BCOTouchFilterMaskOutOfViewBounds: ビューの矩形の中でなければブロック。UIView/UIViewController。
// BCOTouchFilterMaskHitView: ヒットビューであればブロック。UIView/UIViewController。
// BCOTouchFilterMaskNotHitView: ヒットビューでなければブロック。UIView/UIViewController。
// BCOTouchFilterMaskNotOverlapWithHitView: ヒットビューと重なっていなければブロック。UIView/UIViewController。
typedef NS_OPTIONS(NSUInteger, BCOTouchFilterBlockMask) {
    BCOTouchFilterMaskOutOfViewBounds           = 1 << 0,
    BCOTouchFilterMaskHitView                   = 1 << 1,
    BCOTouchFilterMaskNotHitView                = 1 << 2,
    BCOTouchFilterMaskHitViewIsNotSubview       = 1 << 3,
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
