//
//  BCOTouchRooter.m
//  BCOTouchRooter
//
//  Created by 阿部耕平 on 2014/04/22.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOTouchRooter.h"
#import <objc/runtime.h>


//====================================
// BCOTouchRootingInfo (private class)
//====================================
@interface BCOTouchRootingInfo : NSObject 
@property (nonatomic, strong) id<BCOTouchReceiver> receiver;
@property (nonatomic, strong) BCOTouchFilter *filter;
@end

//====================================
// BCOTouchRootingInfo (private class)
//====================================
@implementation BCOTouchRootingInfo
@end


//==========================
// BCOTouchFilter
//==========================
@interface BCOTouchFilter ()

// BCOTouchRooterでのみ使われる
- (BOOL)shouldBlockTouch:(UITouch *)touch toObject:(id)object;

@end

//==========================
// BCOTouchFilter
//==========================
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
    
    if (view && (_blockMask & BCOTouchFilterMaskHitView)) {
        // ヒットビューと同じインスタンスならブロック
        if (view == touch.view) {
            return YES;
        }
    }
    
    if (view && (_blockMask & BCOTouchFilterMaskNotHitView)) {
        // ヒットビューと同じインスタンスならブロック
        if (view != touch.view) {
            return YES;
        }
    }
    
    if (view && (_blockMask & BCOTouchFilterMaskHitViewIsNotSubview)) {
        // ヒットビューが親ビューのサブビューでなければブロック
        if (![self p_existsView:touch.view inSubviews:view.subviews]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)p_existsView:(UIView *)findView inSubviews:(NSArray *)subviews {
    for (UIView *view in subviews) {
        if (view == findView) {
            return YES;
        }
        
        if (view.subviews == nil || [view.subviews count] == 0) {
            continue;
        }
        
        if ([self p_existsView:findView inSubviews:view.subviews]) {
            return YES;
        }
    }
    return NO;
}

@end


//==========================================
// UIWindow category (for method swizzling)
//==========================================
@interface UIWindow (swizzling)

- (void)sendEvent_receive:(UIEvent *)event;

@end


//==========================
// BCOTouchRooter extention
//==========================
@interface BCOTouchRooter ()

@property (nonatomic, strong) NSMutableArray *rootingInfoArray;
@property (nonatomic, strong) BCOTouchFilter *defaultFilter;
@property (nonatomic, strong) NSMutableArray *scrollViewsBuf;

@end

static BCOTouchRooter *p_sharedInstance = nil;

//==========================
// BCOTouchRooter
//==========================
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
        p_sharedInstance = [[BCOTouchRooter alloc] init];
    });
    return p_sharedInstance;
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
            
            // 通常のタッチイベントに対するフィルタでブロック
            // FIXME: けっこう無理矢理な実装。
            // UIScrollViewのscrollEnabledをNOにしておけばなんとかなるっぽい。
            if (rooter.defaultFilter.blocked) {
                if (touch.phase == UITouchPhaseBegan
                    || touch.phase == UITouchPhaseMoved) {
                    UIView *inheritView = touch.view.superview;
                    while (inheritView != nil) {
                        if (![rooter.scrollViewsBuf containsObject:inheritView]
                            && [inheritView isKindOfClass:[UIScrollView class]]
                            && ((UIScrollView *)inheritView).scrollEnabled == YES) {
                            [rooter.scrollViewsBuf addObject:inheritView];
                            ((UIScrollView *)inheritView).scrollEnabled = NO;
                        }
                        inheritView = inheritView.superview;
                    }
                }
                else {
                    UIView *inheritView = touch.view.superview;
                    while (inheritView != nil) {
                        if ([rooter.scrollViewsBuf containsObject:inheritView]) {
                            ((UIScrollView *)inheritView).scrollEnabled = YES;
                            [rooter.scrollViewsBuf removeObject:inheritView];
                        }
                        inheritView = inheritView.superview;
                    }
                }
            }
        }
        
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
    if (rooter.defaultFilter.blocked) {
        return;
    }
    
    // 元々のsendEvent:の実装を呼ぶ
    [self sendEvent_receive:event];
}

@end


