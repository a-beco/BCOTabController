//
//  BCOTouchRooter.m
//  BCOTouchRooter
//
//  Created by 阿部耕平 on 2014/04/22.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOTouchRooter.h"
#import <objc/runtime.h>


#pragma mark - BCOTouchObject
//====================================
// BCOTouchObject (private)
//
// UITouchインスタンスとその発生源のヒットビューを紐づけるためのオブジェクト。
// BCOTouchObjectManager内部で管理する。
//====================================
@interface BCOTouchObject : NSObject
@property (nonatomic, strong) UITouch *touch;
@property (nonatomic, weak) UIView *hitView;
@end

@implementation BCOTouchObject
@end


#pragma mark - BCOTouchObjectManager
//====================================
// BCOTouchObjectManager (private)
//
// 現在のタッチイベントとそのヒットビューを管理するクラス。
// （UITouchのviewプロパティがタッチ途中でnilになることがあるため、
// ヒットビューが取得できなくなる問題があったため作成。）
// BCOTouchRooterでタッチを追加し、BCOTouchFilterから
// ヒットビューを取得するのに使用。
//====================================
@interface BCOTouchObjectManager : NSObject
@property (nonatomic, strong) NSMutableArray *touchObjects;
@end

static BCOTouchObjectManager *p_sharedObjectManager = nil;

@implementation BCOTouchObjectManager

+ (BCOTouchObjectManager *)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        p_sharedObjectManager = [[BCOTouchObjectManager alloc] init];
    });
    return p_sharedObjectManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        _touchObjects = @[].mutableCopy;
    }
    return self;
}

// 現在のタッチイベントを保存する。
// 同じタッチイベントがすでにあるときは無視する。
- (void)saveCurrentTouch:(UITouch *)touch
{
    for (BCOTouchObject *aTouchObject in _touchObjects) {
        if (aTouchObject.touch == touch) {
            // 同じタッチイベントは複数保持しない
            return;
        }
    }
    
    // タッチ開始時のみタッチオブジェクトを配列に追加する
    if (touch.phase == UITouchPhaseBegan) {
        BCOTouchObject *touchObject = [[BCOTouchObject alloc] init];
        touchObject.touch = touch;
        touchObject.hitView = touch.view;
        [_touchObjects addObject:touchObject];
    }
}

// touchesEndedかtouchesCancelledならリストから削除
- (void)removeObsoleteTouches
{
    NSMutableArray *touchObjectsShouldBeRemoved = @[].mutableCopy;
    for (BCOTouchObject *aTouchObject in _touchObjects) {
        // endかcancelならリストから削除する
        if (aTouchObject.touch.phase == UITouchPhaseEnded
            || aTouchObject.touch.phase == UITouchPhaseCancelled) {
            [touchObjectsShouldBeRemoved addObject:aTouchObject];
        }
    }
    
    if ([touchObjectsShouldBeRemoved count] > 0) {
        for (BCOTouchObject *removeObject in touchObjectsShouldBeRemoved) {
            [_touchObjects removeObject:removeObject];
        }
    }
}

- (UIView *)hitViewInTouch:(UITouch *)touch
{
    for (BCOTouchObject *aTouchObject in _touchObjects) {
        if (aTouchObject.touch == touch) {
            return aTouchObject.hitView;
        }
    }
    return nil;
}

@end


#pragma mark - BCOTouchFilter
//====================================
// BCOTouchFilter
//
// レシーバオブジェクトにタッチイベントを通知するか否かを
// blockMaskで指定されたフラグに従って判断するクラス。
//====================================
@interface BCOTouchFilter ()

@property (nonatomic, strong) NSMutableArray *rootingTouches;

// BCOTouchRooterでのみ使われる
- (void)filterEvent:(UIEvent *)event began:(NSSet **)beganSet moved:(NSSet **)movedSet ended:(NSSet **)endSet cancelled:(NSSet **)cancelledSet receiver:(id)receiver;

@end

@implementation BCOTouchFilter

- (id)init
{
    self = [super init];
    if (self) {
        _rootingTouches = @[].mutableCopy;
    }
    return self;
}

- (void)filterEvent:(UIEvent *)event began:(NSSet **)beganSet moved:(NSSet **)movedSet ended:(NSSet **)endedSet cancelled:(NSSet **)cancelledSet receiver:(id)receiver
{
    NSMutableSet *beganSetBuf = [NSMutableSet setWithCapacity:0];
    NSMutableSet *movedSetBuf = [NSMutableSet setWithCapacity:0];
    NSMutableSet *endedSetBuf = [NSMutableSet setWithCapacity:0];
    NSMutableSet *cancelledSetBuf = [NSMutableSet setWithCapacity:0];
    
    for (UITouch *touch in [event allTouches]) {
        
        [[BCOTouchObjectManager sharedManager] saveCurrentTouch:touch];
        
        // フィルタでブロック
        if ([self shouldBlockTouch:touch toObject:receiver]) {
            continue;
        }
        
        switch (touch.phase) {
            case UITouchPhaseBegan:
                [beganSetBuf addObject:touch];
                break;
            case UITouchPhaseMoved:
                [movedSetBuf addObject:touch];
                break;
            case UITouchPhaseEnded:
                [endedSetBuf addObject:touch];
                break;
            case UITouchPhaseCancelled:
                [cancelledSetBuf addObject:touch];
                break;
            default:
                break;
        }
    }
    
    *beganSet = [NSSet setWithSet:beganSetBuf];
    *movedSet = [NSSet setWithSet:movedSetBuf];
    *endedSet = [NSSet setWithSet:endedSetBuf];
    *cancelledSet = [NSSet setWithSet:cancelledSetBuf];
}

- (BOOL)shouldBlockTouch:(UITouch *)touch toObject:(id)object
{
    if (_blocked) {
        [self p_removeRootingTouch:touch];
        return YES;
    }
    
    UIView *view = nil;
    if ([object isKindOfClass:[UIView class]]) {
        view = (UIView *)object;
    } else if ([object isKindOfClass:[UIViewController class]]) {
        view = [(UIViewController *)object view];
    }
    
    if (view && (_blockMask & BCOTouchFilterMaskOutOfViewBounds)) {
        CGPoint touchPoint = [touch locationInView:view];
        if (!CGRectContainsPoint(view.bounds, touchPoint)) {
            [self p_removeRootingTouch:touch];
            return YES;
        }
    }
    
    UIView *hitView = [[BCOTouchObjectManager sharedManager] hitViewInTouch:touch];
    if (view && (_blockMask & BCOTouchFilterMaskHitView)) {
        // ヒットビューと同じインスタンスならブロック
        if (view == hitView) {
            [self p_removeRootingTouch:touch];
            return YES;
        }
    }
    
    if (view && (_blockMask & BCOTouchFilterMaskNotHitView)) {
        // ヒットビューと同じインスタンスならブロック
        if (view != hitView) {
            [self p_removeRootingTouch:touch];
            return YES;
        }
    }
    
    if (view && (_blockMask & BCOTouchFilterMaskHitViewIsNotSubview)) {
        // ヒットビューが親ビューのサブビューでなければブロック
        if (![hitView isDescendantOfView:view]) {
            [self p_removeRootingTouch:touch];
            return YES;
        }
    }
    
    if (_blockMask & BCOTouchFilterMaskMultipleTouch) {
        if ([_rootingTouches count] >= 1 && _rootingTouches[0] != touch) {
            [self p_removeRootingTouch:touch];
            return YES;
        }
    }

    [self p_addRootingTouch:touch];
    return NO;
}

- (void)p_addRootingTouch:(UITouch *)touch
{
    UITouch *touchShouldBeRemoved = nil;
    for (UITouch *aTouch in _rootingTouches) {
        if (aTouch == touch) {
            if (touch.phase == UITouchPhaseEnded
                || touch.phase == UITouchPhaseCancelled) {
                touchShouldBeRemoved = aTouch;
                break;
            }
            return;
        }
    }
    
    // Rootingが終了したら廃棄
    if (touchShouldBeRemoved) {
        [_rootingTouches removeObject:touchShouldBeRemoved];
    }
    
    // Rooting開始時に追加
    if (touch.phase == UITouchPhaseBegan) {
        [_rootingTouches addObject:touch];
    }
}

- (void)p_removeRootingTouch:(UITouch *)touch
{
    if ([_rootingTouches containsObject:touch]) {
        [_rootingTouches removeObject:touch];
    }
}

- (BOOL)p_existsInRootingTouches:(UITouch *)touch
{
    for (UITouch *aTouch in _rootingTouches) {
        if (aTouch == touch) {
            return YES;
        }
    }
    return NO;
}

@end

@interface BCODefaultTouchFilter : BCOTouchFilter

@property (nonatomic, strong) NSMutableArray *unblockedEvents;

- (BOOL)shouldBlockEvent:(UIEvent *)event;

@end

@implementation BCODefaultTouchFilter

- (id)init
{
    self = [super init];
    if (self) {
        _unblockedEvents = @[].mutableCopy;
    }
    return self;
}

- (BOOL)shouldBlockEvent:(UIEvent *)event
{
    if (event.type != UIEventTypeTouches)
        return YES;
    
    if (self.blocked) {
        for (UIEvent *aUnblockedEvent in _unblockedEvents) {
            if (event == aUnblockedEvent) {
                // タッチ開始したものは必ずタッチ終了を呼ぶ.
                for (UITouch *touch in [event allTouches]) {
                    if (touch.phase == UITouchPhaseEnded
                        || touch.phase == UITouchPhaseCancelled) {
                        return NO;
                    }
                }
                break;
            }
        }
        return YES;
    }
    
    // Beganを含むイベントのうち、実行されたものを保持
    for (UITouch *touch in [event allTouches]) {
        if (touch.phase == UITouchPhaseBegan
            && ![_unblockedEvents containsObject:event]) {
            [_unblockedEvents addObject:event];
            break;
        }
    }
    
    return NO;
}

- (void)setBlocked:(BOOL)blocked
{
    [super setBlocked:blocked];
}

@end


#pragma mark - BCOTouchRootingInfo
//====================================
// BCOTouchRootingInfo (private)
//
// レシーバオブジェクトとそのフィルタを紐づけるためのクラス。
// BCOTouchRooter内で使用。
//====================================
@interface BCOTouchRootingInfo : NSObject
@property (nonatomic, strong) id<BCOTouchReceiver> receiver;
@property (nonatomic, strong) BCOTouchFilter *filter;
@end

@implementation BCOTouchRootingInfo
@end


#pragma mark - UIWindow interface
//====================================
// UIWindow category
//
// method swizzling 用のメソッド
//====================================
@interface UIWindow (swizzling)

- (void)sendEvent_receive:(UIEvent *)event;

@end


#pragma mark - BCOTouchRooter
//====================================
// BCOTouchRooter
//====================================
@interface BCOTouchRooter ()

@property (nonatomic, strong) NSMutableArray *rootingInfoArray;
@property (nonatomic, strong) BCOTouchFilter *defaultFilter;

@end

static BCOTouchRooter *p_sharedRooter = nil;

@implementation BCOTouchRooter

- (id)init
{
    self = [super init];
    if (self) {
        _rootingInfoArray = @[].mutableCopy;
        _defaultFilter = [[BCODefaultTouchFilter alloc] init];
        
        // method swizzling
        [self p_processMethodSwizzlingFromClass:[UIWindow class]
                                        fromSEL:@selector(sendEvent:)
                                        toClass:[UIWindow class]
                                          toSEL:@selector(sendEvent_receive:)];
    }
    return self;
}

#pragma mark - BCOTouchRooter public

+ (BCOTouchRooter *)sharedRooter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        p_sharedRooter = [[BCOTouchRooter alloc] init];
    });
    return p_sharedRooter;
}

- (void)addReceiver:(id<BCOTouchReceiver>)receiver
{
    if ([self p_containsReceiver:receiver]) {
        return;
    }
    
    BCOTouchRootingInfo *rootingInfo = [[BCOTouchRootingInfo alloc] init];
    rootingInfo.receiver = receiver;
    
    BCOTouchFilter *touchFilter = [[BCOTouchFilter alloc] init];
    rootingInfo.filter = touchFilter;
    
    [_rootingInfoArray addObject:rootingInfo];
}

- (void)removeReceiver:(id<BCOTouchReceiver>)receiver
{
    if ([self p_containsReceiver:receiver]) {
        BCOTouchRootingInfo *rootingInfo = [self p_touchRootingInfoOfReceiver:receiver];
        if (rootingInfo) {
            [_rootingInfoArray removeObject:rootingInfo];
        }
    }
}

- (BCOTouchFilter *)defaultFilter
{
    return _defaultFilter;
}

- (BCOTouchFilter *)filterForReceiver:(id<BCOTouchReceiver>)receiver
{
    BCOTouchRootingInfo *rootingInfo = [self p_touchRootingInfoOfReceiver:receiver];
    if (rootingInfo) {
        return rootingInfo.filter;
    }
    return nil;
}

#pragma mark - BCOTouchRooter private

- (BCOTouchRootingInfo *)p_touchRootingInfoOfReceiver:(id<BCOTouchReceiver>)receiver
{
    for (BCOTouchRootingInfo *rootingInfo in _rootingInfoArray) {
        if (rootingInfo.receiver == receiver) {
            return rootingInfo;
        }
    }
    return nil;
}

- (BOOL)p_containsReceiver:(id<BCOTouchReceiver>)receiver
{
    for (BCOTouchRootingInfo *rootingInfo in _rootingInfoArray) {
        if (rootingInfo.receiver == receiver) {
            return YES;
        }
    }
    return NO;
}

- (void)p_processMethodSwizzlingFromClass:(Class)fromClass
                                  fromSEL:(SEL)fromSEL
                                  toClass:(Class)toClass
                                    toSEL:(SEL)toSEL
{
    Method fromMethod = class_getInstanceMethod(fromClass, fromSEL);
    Method toMethod = class_getInstanceMethod(toClass, toSEL);
    method_exchangeImplementations(fromMethod, toMethod);
}

@end


#pragma mark - UIWindow implementation
//====================================
// UIWindow category
//
// method swizzling用のメソッド
//====================================
@implementation UIWindow (swizzling)

// UIWindowのsendEventをこのメソッドで置き換える。
- (void)sendEvent_receive:(UIEvent *)event
{
    // タッチイベントをレシーバに通知
    BCOTouchRooter *rooter = [BCOTouchRooter sharedRooter];
    for (BCOTouchRootingInfo *rootingInfo in rooter.rootingInfoArray) {
        
        id<BCOTouchReceiver> receiver = rootingInfo.receiver;
        BCOTouchFilter *filter = rootingInfo.filter;
        
        // フィルタリング
        NSSet* beganSet, *movedSet, *endedSet, *cancelledSet;
        [filter filterEvent:event
                      began:&beganSet
                      moved:&movedSet
                      ended:&endedSet
                  cancelled:&cancelledSet
                   receiver:receiver];
        
        [[BCOTouchObjectManager sharedManager] removeObsoleteTouches];
        
        if ([beganSet count] > 0
            && [receiver respondsToSelector:@selector(didReceiveTouchesBegan:event:)]) {
            [receiver didReceiveTouchesBegan:beganSet event:event];
        }
        
        if ([movedSet count] > 0
            && [receiver respondsToSelector:@selector(didReceiveTouchesMoved:event:)]) {
            [receiver didReceiveTouchesMoved:movedSet.copy event:event];
        }
        
        if ([endedSet count] > 0
            && [receiver respondsToSelector:@selector(didReceiveTouchesEnded:event:)]) {
            [receiver didReceiveTouchesEnded:endedSet.copy event:event];
        }
        
        if ([cancelledSet count] > 0
            && [receiver respondsToSelector:@selector(didReceiveTouchesCancelled:event:)]) {
            [receiver didReceiveTouchesCancelled:cancelledSet.copy event:event];
        }
    }
    
    // 通常のタッチイベントに対するフィルタでブロック
    if ([(BCODefaultTouchFilter *)rooter.defaultFilter shouldBlockEvent:event]) {
        return;
    }
    
    // 元々のsendEvent:の実装を呼ぶ
    [self sendEvent_receive:event];
}

@end


