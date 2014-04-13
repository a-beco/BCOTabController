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

const CGFloat kBCOPageControllerStartMovingThreshold = 10;
const CGFloat kBCOPageControllerLengthFromFingerToRightEdge = 20;
const NSTimeInterval kBCOPageControllerMovingAnimationDuration = 0.2;

typedef NS_ENUM(NSUInteger, BCOPageControllerMovingState) {
    kBCOPageControllerMovingStateNone,
    kBCOPageControllerMovingStateNext,
    kBCOPageControllerMovingStatePrevious
};

@interface BCOPageController ()
@property (nonatomic, strong) UIViewController *baseViewController;
@property (nonatomic, strong) UIViewController *movingViewController;
@end

@implementation BCOPageController {
    CGFloat _touchBeginX;
    CGFloat _currentX;
    BCOPageControllerMovingState _movingState;
}

- (id)init
{
    return [self initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.multipleTouchEnabled = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
        if (distance > kBCOPageControllerStartMovingThreshold) {
            [self p_startMovingWithState:kBCOPageControllerMovingStateNext];
        }
        else if (distance < -kBCOPageControllerStartMovingThreshold) {
            [self p_startMovingWithState:kBCOPageControllerMovingStatePrevious];
        }
    }
    else {
        [self p_layoutMovingViewAnimated:YES completion:nil];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_movingState == kBCOPageControllerMovingStateNone) {
        return;
    }
    
    _currentX = getX(touches, self.view);
    CGFloat previousX = getPreviousX(touches, self.view);
    
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
    if (_baseViewController) {
        _baseViewController.view.frame = CGRectMake(0,
                                                    0,
                                                    self.view.bounds.size.width,
                                                    self.view.bounds.size.height);
    }
}

- (void)p_layoutMovingViewAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    if (_movingState == kBCOPageControllerMovingStateNone) {
        return;
    }
    
    if (_movingViewController) {
        [self.view bringSubviewToFront:_movingViewController.view];
        
        CGSize movingViewSize = _movingViewController.view.bounds.size;
        if (animated) {
            [UIView animateWithDuration:kBCOPageControllerMovingAnimationDuration animations:^{
                _movingViewController.view.frame = CGRectMake(_currentX - movingViewSize.width + kBCOPageControllerLengthFromFingerToRightEdge,
                                                              0,
                                                              movingViewSize.width,
                                                              movingViewSize.height);
            } completion:^(BOOL finished) {
                if (completion) {
                    completion();
                }
            }];
        }
        else {
            completion();
        }
    }
}

- (void)p_startMovingWithState:(BCOPageControllerMovingState)movingState
{
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
    [self p_layoutMovingViewAnimated:YES completion:nil];
}

- (void)p_cancelMovingAnimated:(BOOL)animated
{
    _currentX = (_movingState == kBCOPageControllerMovingStateNext) ? self.view.bounds.size.width : 0;
    _currentX -= kBCOPageControllerLengthFromFingerToRightEdge;
    
    [self p_layoutMovingViewAnimated:animated completion:^{
        
        if (_movingState == kBCOPageControllerMovingStateNext) {
            [_baseViewController.view removeFromSuperview];
            self.baseViewController = _movingViewController;
        }
        else {
            [_movingViewController.view removeFromSuperview];
        }
        self.movingViewController = nil;
        
        _movingState = kBCOPageControllerMovingStateNone;
    }];
}

- (void)p_completeMovingAnimated:(BOOL)animated
{
    if (_movingState == kBCOPageControllerMovingStateNone) {
        return;
    }
    
    _currentX = (_movingState == kBCOPageControllerMovingStateNext) ? 0 : self.view.bounds.size.width;
    _currentX -= kBCOPageControllerLengthFromFingerToRightEdge;
    
    [self p_layoutMovingViewAnimated:animated completion:^{
        
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
