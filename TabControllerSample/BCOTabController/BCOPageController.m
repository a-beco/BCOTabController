//
//  BCOPageController.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOPageController.h"
#import "BCOTouchRooter.h"

CGFloat getX(NSSet *touches, UIView *view)
{
    return [[touches anyObject] locationInView:view].x;
}

CGFloat getPreviousX(NSSet *touches, UIView *view)
{
    return [[touches anyObject] previousLocationInView:view].x;
}

//==============================================

const CGFloat kBCOPageControllerStartMovingThreshold = 30;
const CGFloat kBCOPageControllerVelocityGradient = 0.2;
const NSTimeInterval kBCOPageControllerMovingAnimationDuration = 0.3;

typedef NS_ENUM(NSUInteger, BCOPageControllerMovingState) {
    kBCOPageControllerMovingStateNone,
    kBCOPageControllerMovingStateNext,
    kBCOPageControllerMovingStatePrevious,
};

@interface BCOPageController () <BCOTouchReceiver>
@property (nonatomic, strong) UIViewController *baseViewController;
@property (nonatomic, strong) UIViewController *movingViewController;
@property (nonatomic, strong) NSTimer *trackingTimer;
@property (nonatomic, strong) UIControl *blockTouchCoverView;
@end

@implementation BCOPageController {
    CGFloat _touchBeginX;
    CGFloat _currentX;
    BCOPageControllerMovingState _movingState;
    BOOL _isAnimating;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)init
{
    return [self initWithNibName:nil bundle:nil];
}

- (void)initialize
{
    // 将来的に何かするかも
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.multipleTouchEnabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self p_cancelMovingAnimated:NO];
    [_trackingTimer invalidate];
}

- (void)viewDidDisappear:(BOOL)animated
{
    // タッチイベントのレシーバから削除
    BCOTouchRooter *rooter = [BCOTouchRooter sharedRooter];
    [rooter removeReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    // 表示される直前にページをリロード
    [self p_reloadPage];
    
    // タッチイベントのレシーバに指定
    BCOTouchRooter *rooter = [BCOTouchRooter sharedRooter];
    [rooter addReceiver:self];
    [rooter filterForReceiver:self].blockMask = BCOTouchFilterMaskHitViewIsNotSubview
                                                | BCOTouchFilterMaskMultipleTouch;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - touch

- (void)didReceiveTouchesBegan:(NSSet *)touches event:(UIEvent *)event
{
    _touchBeginX = getX(touches, self.view);
}

- (void)didReceiveTouchesMoved:(NSSet *)touches event:(UIEvent *)event
{
    _currentX = getX(touches, self.view);
    CGFloat distance = _touchBeginX - _currentX;
    
    if (_movingState == kBCOPageControllerMovingStateNone && !_movingViewController) {
        // 一定幅X方向にスライドしたらビューを動かし始める
        if (distance > kBCOPageControllerStartMovingThreshold) {
            [self p_startMovingWithState:kBCOPageControllerMovingStateNext];
        }
        else if (distance < -kBCOPageControllerStartMovingThreshold) {
            [self p_startMovingWithState:kBCOPageControllerMovingStatePrevious];
        }
    }
}

- (void)didReceiveTouchesEnded:(NSSet *)touches event:(UIEvent *)event
{
    if (_movingState == kBCOPageControllerMovingStateNone || _isAnimating) {
        return;
    }
    
    _currentX = getX(touches, self.view);
    CGFloat previousX = getPreviousX(touches, self.view);
    
    // 直前のタッチ座標から指が動いている方向を判定し、cancelかcompleteか判断する
    if (previousX - _currentX > 0) {
        if (_movingState == kBCOPageControllerMovingStateNext) {
            [self p_completeMovingAnimated:YES];
        }
        else if (_movingState == kBCOPageControllerMovingStatePrevious) {
            [self p_cancelMovingAnimated:YES];
        }
    }
    else {
        if (_movingState == kBCOPageControllerMovingStateNext) {
            [self p_cancelMovingAnimated:YES];
        }
        else if (_movingState == kBCOPageControllerMovingStatePrevious) {
            [self p_completeMovingAnimated:YES];
        }
    }
}

- (void)didReceiveTouchesCancelled:(NSSet *)touches event:(UIEvent *)event
{
    if (_movingState == kBCOPageControllerMovingStateNone) {
        return;
    }
    
    [self p_cancelMovingAnimated:NO];
}

#pragma mark - property

// ページのインデックスをセットするとページを移動
- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    UIViewController *nextViewController = [self p_viewControllerFromDataSourceAtIndex:selectedIndex];
    if (!nextViewController) {
        return;
    }
    
    _selectedIndex = selectedIndex;
    [self p_reloadPage];
}

#pragma mark - private

// ビューを再ロード
- (void)p_reloadPage
{
    UIViewController *displayViewController = [self p_viewControllerFromDataSourceAtIndex:_selectedIndex];
    if (!displayViewController) {
        return;
    }
    
    // ビューを動かしているときであれば一旦キャンセル
    if (_movingViewController) {
        [self p_cancelMovingAnimated:NO];
    }
    
    // 現在表示しているビューを取り除く
    if (_baseViewController) {
        [_baseViewController.view removeFromSuperview];
        [_baseViewController removeFromParentViewController];
    }
    
    // 表示するビューをセット
    self.baseViewController = displayViewController;
    [self.view addSubview:_baseViewController.view];
    [self addChildViewController:_baseViewController];
    
    [self p_layoutBaseView];
}

// 表示するビューを位置合わせ
- (void)p_layoutBaseView
{
    if (!_baseViewController) {
        return;
    }
    
    _baseViewController.view.frame = CGRectMake(0,
                                                0,
                                                self.view.bounds.size.width,
                                                self.view.bounds.size.height);
}

// 指の動きに_movingViewControllerを追尾させる処理を開始
- (void)p_startTarckingMovingView
{
    [self.view bringSubviewToFront:_movingViewController.view];
    
    // moving view の位置を調整
    CGSize movingViewSize = _movingViewController.view.bounds.size;
    if (_movingState == kBCOPageControllerMovingStateNext) {
        _movingViewController.view.frame = CGRectMake(0,
                                                      0,
                                                      movingViewSize.width,
                                                      movingViewSize.height);
    }
    else {
        _movingViewController.view.frame = CGRectMake(-movingViewSize.width,
                                                      0,
                                                      movingViewSize.width,
                                                      movingViewSize.height);
    }
    
    // trackingFired:で
    self.trackingTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                          target:self
                                                        selector:@selector(p_trackingFired:)
                                                        userInfo:nil
                                                         repeats:YES];
}

// 指の動きに_movingViewControllerを追尾させる処理を終了
- (void)p_endTrackingMovingView
{
    [_trackingTimer invalidate];
}

// 指の位置に合わせて_movingViewControllerのviewを動かす
- (void)p_trackingFired:(NSTimer *)timer
{
    if (_movingState == kBCOPageControllerMovingStateNone || !_movingViewController) {
        [self p_endTrackingMovingView];
        return;
    }
    
    // 移動するX座標を決める
    CGRect movingViewFrame = _movingViewController.view.frame;
    CGFloat destinationX = 0;
    if (_movingState == kBCOPageControllerMovingStateNext) {
        destinationX = -(_touchBeginX - _currentX);
    }
    else if (_movingState == kBCOPageControllerMovingStatePrevious) {
        destinationX = _currentX - movingViewFrame.size.width;
    }
    
    // 移動先に近づくほどステップ幅が小さくなるよう調整
    CGFloat diffX = destinationX - movingViewFrame.origin.x;
    CGFloat step = kBCOPageControllerVelocityGradient * diffX;
    
    _movingViewController.view.frame = CGRectOffset(movingViewFrame, step, 0);
}

// xの位置に_movingViewControllerを移動させる
- (void)p_moveMovingViewToX:(CGFloat)x animated:(BOOL)animated completion:(void (^)(void))completion
{
    CGSize movingViewSize = _movingViewController.view.bounds.size;
    CGRect toFrame = CGRectMake(x,
                                0,
                                movingViewSize.width,
                                movingViewSize.height);
    
    if (animated) {
        [UIView animateWithDuration:kBCOPageControllerMovingAnimationDuration animations:^{
            _movingViewController.view.frame = toFrame;
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    }
    else {
        _movingViewController.view.frame = toFrame;
        completion();
    }
}

// 水平方向のページ移動を開始
- (void)p_startMovingWithState:(BCOPageControllerMovingState)movingState
{
    if (movingState == kBCOPageControllerMovingStateNone) {
        return;
    }
    
    if (movingState == kBCOPageControllerMovingStateNext) {
        // 次のページに移動
        UIViewController *nextViewController = [self p_viewControllerFromDataSourceAtIndex:_selectedIndex + 1];
        if (!nextViewController) {
            return;
        }
        
        [self.view addSubview:nextViewController.view];
        self.movingViewController = _baseViewController;
        self.baseViewController = nextViewController;
    }
    else {
        // 前のページに移動
        if (_selectedIndex == 0) {
            return;
        }
        
        UIViewController *previousViewController = [self p_viewControllerFromDataSourceAtIndex:_selectedIndex - 1];
        if (!previousViewController) {
            return;
        }
        
        [self.view addSubview:previousViewController.view];
        self.movingViewController = previousViewController;
    }
    
    _movingState = movingState;
    
    [self p_layoutBaseView];
    [self p_startTarckingMovingView];
    
    // 通常のタッチを制限
    [self p_blockAllTouches:YES];
}

// 水平方向のページ移動をキャンセル
- (void)p_cancelMovingAnimated:(BOOL)animated
{
    if (!_movingViewController) {
        return;
    }
    
    CGFloat destinationX = 0;
    if (_movingState == kBCOPageControllerMovingStatePrevious) {
        destinationX = -self.view.bounds.size.width;
    }
    
    [self p_endTrackingMovingView];
    
    _isAnimating = YES;
    [self p_moveMovingViewToX:destinationX animated:YES completion:^{
        
        if (_movingState == kBCOPageControllerMovingStateNext) {
            [_baseViewController.view removeFromSuperview];
            self.baseViewController = _movingViewController;
        }
        else {
            [_movingViewController.view removeFromSuperview];
        }
        self.movingViewController = nil;
        
        _movingState = kBCOPageControllerMovingStateNone;
        _isAnimating = NO;
        
        // 通常のタッチ制限を解除
        [self p_blockAllTouches:NO];
    }];
}

// 水平方向のページ移動を完了する
- (void)p_completeMovingAnimated:(BOOL)animated
{
    if (_movingState == kBCOPageControllerMovingStateNone) {
        return;
    }
    
    // ページが移動するX座標を決定
    CGFloat destinationX = 0;
    if (_movingState == kBCOPageControllerMovingStateNext) {
        destinationX = -self.view.bounds.size.width;
    }
    
    // タッチ座標の追跡を終了
    [self p_endTrackingMovingView];
    
    // 指定したX座標に_movingViewControllerを移動させる
    _isAnimating = YES;
    [self p_moveMovingViewToX:destinationX animated:YES completion:^{

        // _movingViewControllerを削除して、_baseViewControllerを表示する
        if (_movingState == kBCOPageControllerMovingStateNext) {
            [_movingViewController.view removeFromSuperview];
            [_movingViewController removeFromParentViewController];
        }
        else {
            [_baseViewController.view removeFromSuperview];
            [_baseViewController removeFromParentViewController];
            self.baseViewController = _movingViewController;
        }
        [self addChildViewController:_baseViewController];
        self.movingViewController = nil;
        
        // インデックス更新
        if (_movingState == kBCOPageControllerMovingStateNext) {
            _selectedIndex ++;
        }
        else if (_movingState == kBCOPageControllerMovingStatePrevious) {
            _selectedIndex --;
        }
        
        _movingState = kBCOPageControllerMovingStateNone;
        _isAnimating = NO;
        
        // 通常のタッチ制限を解除
        [self p_blockAllTouches:NO];
        
        if ([_delegate respondsToSelector:@selector(pageController:didMoveToIndex:)]) {
            [_delegate pageController:self didMoveToIndex:_selectedIndex];
        }
    }];
}

- (UIViewController *)p_viewControllerFromDataSourceAtIndex:(NSUInteger)index
{
    if ([_dataSource respondsToSelector:@selector(pageController:pageForIndex:)]) {
        return [_dataSource pageController:self pageForIndex:index];
    }
    return nil;
}

// 全てのタッチイベントをブロックする。
//
// note: isBlockedをYESにした時に全てのUIScrollViewのscrollEnabledをNOにする。
// そのあとNOを指定すれば元の状態に戻す。
- (void)p_blockAllTouches:(BOOL)isBlocked
{
    [[BCOTouchRooter sharedRooter] defaultFilter].blocked = isBlocked;
    
    static NSMutableArray *disabledScrollViews = nil;
    if (disabledScrollViews) {
        for (UIScrollView *scrollView in disabledScrollViews) {
            scrollView.scrollEnabled = YES;
        }
        disabledScrollViews = nil;
    }
    
    // scrollEnabledがYESになっているscrollviewを見つけてscrollEnabledをNOにする
    // NOにしたものはisBlockedをNOにした時に元に戻すので、副作用は最小限になる。
    if (isBlocked) {
        disabledScrollViews = @[].mutableCopy;
        NSArray *allChildViews = [self p_allChildViewsBelowView:self.view];
        for (UIView *aChildView in allChildViews) {
            if ([aChildView isKindOfClass:[UIScrollView class]]) {
                UIScrollView *scrollView = (UIScrollView *)aChildView;
                if (scrollView.scrollEnabled == YES) {
                    scrollView.scrollEnabled = NO;
                    [disabledScrollViews addObject:scrollView];
                }
            }
        }
    }
}

// 引数view以下の全ての子ビュー、孫ビュー、ひ孫ビュー...を再帰的に取得し、NSArrayで返す。
- (NSArray *)p_allChildViewsBelowView:(UIView *)view
{
    NSMutableArray *subviewsBuf = @[].mutableCopy;
    for (UIView *subview in view.subviews) {
        [subviewsBuf addObject:subview];
        
        if ([subview.subviews count] != 0) {
            // 再帰的なメソッド呼び出し
            NSArray *subsubviews = [self p_allChildViewsBelowView:subview];
            [subviewsBuf addObjectsFromArray:subsubviews];
        }
    }
    return [subviewsBuf copy];
}

@end
