//
//  BCOTouchRooter.m
//  BCOTouchRooter
//
//  Created by 阿部耕平 on 2014/04/22.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOTouchRooter.h"
#import <objc/runtime.h>


#pragma mark - BCOTouchRootingInfo
//====================================
// BCOTouchRootingInfo (private)
//====================================
@interface BCOTouchRootingInfo : NSObject 
@property (nonatomic, strong) id<BCOTouchReceiver> receiver;
@property (nonatomic, strong) BCOTouchFilter *filter;
@end

@implementation BCOTouchRootingInfo
@end


#pragma mark - BCOTouchObject
//==========================
// BCOTouchObject (private)
//==========================
@interface BCOTouchObject : NSObject
@property (nonatomic, strong) UITouch *touch;
@property (nonatomic, strong) UIView *hitView;
@end

@implementation BCOTouchObject
@end


#pragma mark - BCOTouchObjectManager
//==========================
// BCOTouchObjectManager (private)
//==========================
@interface BCOTouchObjectManager : NSObject

@property (nonatomic, strong) NSMutableArray *touchObjects;
@property (nonatomic, strong) NSMutableArray *hitViews;

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
        _hitViews = @[].mutableCopy;
    }
    return self;
}

- (void)receiveTouch:(UITouch *)touch
{
    BCOTouchObject *touchObjectShouldBeRemoved = nil;
    for (BCOTouchObject *aTouchObject in _touchObjects) {
        if (aTouchObject.touch == touch) {
            if (touch.phase == UITouchPhaseEnded
                     || touch.phase == UITouchPhaseCancelled) {
                touchObjectShouldBeRemoved = aTouchObject;
            }
            return;
        }
    }
    
    if (touchObjectShouldBeRemoved) {
        [_touchObjects removeObject:touchObjectShouldBeRemoved];
        return;
    }
    
    if (touch.phase == UITouchPhaseBegan) {
        BCOTouchObject *touchObject = [[BCOTouchObject alloc] init];
        touchObject.touch = touch;
        touchObject.hitView = touch.view;
        [_touchObjects addObject:touchObject];
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
//==========================
// BCOTouchFilter
//==========================
@interface BCOTouchFilter ()

// BCOTouchRooterでのみ使われる
- (BOOL)shouldBlockTouch:(UITouch *)touch toObject:(id)object;

@end

@implementation BCOTouchFilter

- (BOOL)shouldBlockTouch:(UITouch *)touch toObject:(id)object
{
    if (_blocked) {
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
            return YES;
        }
    }
    
    UIView *hitView = [[BCOTouchObjectManager sharedManager] hitViewInTouch:touch];
    if (view && (_blockMask & BCOTouchFilterMaskHitView)) {
        // ヒットビューと同じインスタンスならブロック
        if (view == hitView) {
            return YES;
        }
    }
    
    if (view && (_blockMask & BCOTouchFilterMaskNotHitView)) {
        // ヒットビューと同じインスタンスならブロック
        if (view != hitView) {
            return YES;
        }
    }
    
    if (view && (_blockMask & BCOTouchFilterMaskHitViewIsNotSubview)) {
        // ヒットビューが親ビューのサブビューでなければブロック
        if (![hitView isDescendantOfView:view]) {
            return YES;
        }
    }
    
    return NO;
}

@end


#pragma mark - UIWindow interface
//==========================================
// UIWindow category (for method swizzling)
//==========================================
@interface UIWindow (swizzling)

- (void)sendEvent_receive:(UIEvent *)event;

@end


#pragma mark - BCOTouchRooter
//==========================
// BCOTouchRooter
//==========================
@interface BCOTouchRooter ()

@property (nonatomic, strong) NSMutableArray *rootingInfoArray;
@property (nonatomic, strong) BCOTouchFilter *defaultFilter;
@property (nonatomic, strong) NSMutableArray *scrollViewsBuf;

@end

static BCOTouchRooter *p_sharedRooter = nil;

@implementation BCOTouchRooter

- (id)init
{
    self = [super init];
    if (self) {
        _rootingInfoArray = @[].mutableCopy;
        _defaultFilter = [[BCOTouchFilter alloc] init];
        _scrollViewsBuf = @[].mutableCopy;
        
        // method swizzling
        [self p_processMethodSwizzlingFromClass:[UIWindow class]
                                        fromSEL:@selector(sendEvent:)
                                        toClass:[UIWindow class]
                                          toSEL:@selector(sendEvent_receive:)];
    }
    return self;
}

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

#pragma mark - private

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
//==========================================
// UIWindow category (for method swizzling)
//==========================================
@implementation UIWindow (swizzling)

// UIWindowのsendEventをこのメソッドで置き換える。
- (void)sendEvent_receive:(UIEvent *)event
{
    // タッチイベントをレシーバに通知
    BCOTouchRooter *rooter = [BCOTouchRooter sharedRooter];
    for (BCOTouchRootingInfo *rootingInfo in rooter.rootingInfoArray) {
        
        id<BCOTouchReceiver> receiver = rootingInfo.receiver;
        BCOTouchFilter *filter = rootingInfo.filter;
        
        // phaseごとにsetを分ける
        NSMutableSet *beganSet = [NSMutableSet setWithCapacity:0];
        NSMutableSet *movedSet = [NSMutableSet setWithCapacity:0];
        NSMutableSet *endedSet = [NSMutableSet setWithCapacity:0];
        NSMutableSet *cancelledSet = [NSMutableSet setWithCapacity:0];
        NSSet *allTouches = [event allTouches];
        for (UITouch *touch in allTouches) {
            
            [[BCOTouchObjectManager sharedManager] receiveTouch:touch];
            
            // フィルタでブロック
            if ([filter shouldBlockTouch:touch toObject:receiver]) {
                continue;
            }
            
            switch (touch.phase) {
                case UITouchPhaseBegan:
                    [beganSet addObject:touch];
                    break;
                case UITouchPhaseMoved:
                    [movedSet addObject:touch];
                    break;
                case UITouchPhaseEnded:
                    [endedSet addObject:touch];
                    break;
                case UITouchPhaseCancelled:
                    [cancelledSet addObject:touch];
                    break;
                default:
                    break;
            }
        }
        
        if ([beganSet count] > 0
            && [receiver respondsToSelector:@selector(didReceiveTouchesBegan:event:)]) {
            [receiver didReceiveTouchesBegan:beganSet event:event];
            NSLog(@"began");
        }
        
        if ([movedSet count] > 0
            && [receiver respondsToSelector:@selector(didReceiveTouchesMoved:event:)]) {
            [receiver didReceiveTouchesMoved:movedSet.copy event:event];
            NSLog(@"moved");
        }
        
        if ([endedSet count] > 0
            && [receiver respondsToSelector:@selector(didReceiveTouchesEnded:event:)]) {
            [receiver didReceiveTouchesEnded:endedSet.copy event:event];
            NSLog(@"end");
        }
        
        if ([cancelledSet count] > 0
            && [receiver respondsToSelector:@selector(didReceiveTouchesCancelled:event:)]) {
            [receiver didReceiveTouchesCancelled:cancelledSet.copy event:event];
            NSLog(@"cancel");
        }
    }
    
    // 通常のタッチイベントに対するフィルタでブロック
    if (rooter.defaultFilter.blocked) {
        return;
    }
    
    // 元々のsendEvent:の実装を呼ぶ
    [self sendEvent_receive:event];
}

@end


