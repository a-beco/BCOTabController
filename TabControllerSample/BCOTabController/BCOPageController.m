//
//  BCOPageController.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOPageController.h"

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

@interface BCOPageController ()
@property (nonatomic, strong) UIViewController *baseViewController;
@property (nonatomic, strong) UIViewController *movingViewController;
@property (nonatomic, strong) NSTimer *trackingTimer;
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
    // 将来的に何かやるかもしれないので一応用意
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

- (void)viewWillAppear:(BOOL)animated
{
    [self p_reloadView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _touchBeginX = getX(touches, self.view);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
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

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_movingState == kBCOPageControllerMovingStateNone) {
        return;
    }
    
    [self p_cancelMovingAnimated:NO];
}

#pragma mark - property

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    UIViewController *nextViewController = [self p_viewControllerFromDataSourceAtIndex:selectedIndex];
    if (!nextViewController) {
        return;
    }
    
    _selectedIndex = selectedIndex;
    [self p_reloadView];
}

#pragma mark - private

- (void)p_reloadView
{
    UIViewController *currentViewController = [self p_viewControllerFromDataSourceAtIndex:_selectedIndex];
    if (!currentViewController) {
        return;
    }
    
    if (_movingViewController) {
        [self p_cancelMovingAnimated:NO];
    }
    
    if (_baseViewController) {
        [_baseViewController.view removeFromSuperview];
        [_baseViewController removeFromParentViewController];
    }
    
    self.baseViewController = currentViewController;
    [self.view addSubview:_baseViewController.view];
    [self addChildViewController:_baseViewController];
    [self p_layoutBaseView];
}

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

- (void)p_startTarckingMovingView
{
    [self.view bringSubviewToFront:_movingViewController.view];
    self.trackingTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                          target:self
                                                        selector:@selector(trackingFired:)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)p_endTrackingMovingView
{
    [_trackingTimer invalidate];
}

- (void)trackingFired:(NSTimer *)timer
{
    if (_movingState == kBCOPageControllerMovingStateNone || !_movingViewController) {
        [self p_endTrackingMovingView];
        return;
    }
    
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

- (void)p_startMovingWithState:(BCOPageControllerMovingState)movingState
{
    NSLog(@"start");
    if (movingState == kBCOPageControllerMovingStateNone) {
        return;
    }
    
    if (movingState == kBCOPageControllerMovingStateNext) {
        UIViewController *nextViewController = [self p_viewControllerFromDataSourceAtIndex:_selectedIndex + 1];
        if (!nextViewController) {
            return;
        }
        
        [self.view addSubview:nextViewController.view];
        self.movingViewController = _baseViewController;
        self.baseViewController = nextViewController;
    }
    else {
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
}

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
    }];
}

- (void)p_completeMovingAnimated:(BOOL)animated
{
    NSLog(@"complete");
    if (_movingState == kBCOPageControllerMovingStateNone) {
        return;
    }
    
    CGFloat destinationX = 0;
    if (_movingState == kBCOPageControllerMovingStateNext) {
        destinationX = -self.view.bounds.size.width;
    }
    else {
        destinationX = 0;
    }
    
    [self p_endTrackingMovingView];
    
    _isAnimating = YES;
    [self p_moveMovingViewToX:destinationX animated:YES completion:^{
        NSLog(@"complete completion");
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

@end
