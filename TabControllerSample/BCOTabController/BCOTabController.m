//
//  BCOTabController.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/12.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOTabController.h"
#import "BCOTabListView.h"


const CGFloat BCOTabControllerStatusBarHeight = 20.0;
const CGFloat BCOTabControllerTabListViewHeight = 44.0;

@interface BCOTabController () <BCOTabListViewDelegate>

@property (nonatomic, strong) BCOTabListView *tabListView;
@property (nonatomic, strong) UIView *containerView;

@end


@implementation BCOTabController

@dynamic tabColors;
@dynamic selectedIndex;

- (id)init
{
    return [self initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
        
        _tabListView = [[BCOTabListView alloc] initWithFrame:CGRectZero];
        _tabListView.delegate = self;
        [self.view addSubview:_tabListView];
        
        [self p_layoutViews];

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self
                   selector:@selector(applicationDidChangeStatusBarFrameNotification:)
                       name:UIApplicationDidChangeStatusBarFrameNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(applicationDidBecomeActiveNotification:)
                       name:UIApplicationDidBecomeActiveNotification
                     object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - property

- (void)setViewControllers:(NSArray *)viewControllers
{
    _viewControllers = [viewControllers copy];
    _tabListView.titles = [self p_viewControllerTitles];
    
    self.selectedIndex = _tabListView.selectedIndex;
}

- (NSArray *)tabColors
{
    return _tabListView.tabColors;
}

- (void)setTabColors:(NSArray *)tabColors
{
    _tabListView.tabColors = tabColors;
}

- (UIViewController *)selectedViewController
{
    if ([_viewControllers count] > self.selectedIndex) {
        return _viewControllers[self.selectedIndex];
    }
    return nil;
}

- (NSUInteger)selectedIndex
{
    return _tabListView.selectedIndex;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    _tabListView.selectedIndex = selectedIndex;
}

#pragma mark - private

- (void)p_layoutViews
{
    _tabListView.frame = CGRectMake(0,
                                    [UIApplication sharedApplication].statusBarFrame.size.height,
                                    self.view.bounds.size.width,
                                    BCOTabControllerTabListViewHeight);
    
    if (_containerView) {
        CGFloat containerY = _tabListView.frame.origin.y + _tabListView.frame.size.height;
        _containerView.frame = CGRectMake(0,
                                          containerY,
                                          self.view.bounds.size.width,
                                          self.view.bounds.size.height - containerY);
    }
}

- (void)p_showViewControllerAtIndex:(NSUInteger)index
{
    if (!_viewControllers || [_viewControllers count] == 0) {
        return;
    }
    
    for (UIViewController *vc in self.childViewControllers) {
        [vc removeFromParentViewController];
        [vc.view removeFromSuperview];
    }
    
    if ([_viewControllers count] <= index) {
        index = 0;
    }
    
    UIViewController *viewController = _viewControllers[index];
    self.containerView = viewController.view;
    [self.view addSubview:_containerView];
    [self addChildViewController:viewController];
    
    [self p_layoutViews];
}

- (NSArray *)p_viewControllerTitles
{
    NSMutableArray *titlesBuf = @[].mutableCopy;
    for (UIViewController *vc in _viewControllers) {
        [titlesBuf addObject:vc.title];
    }
    return [titlesBuf copy];
}

#pragma mark - delegate

- (void)tabListView:(BCOTabListView *)tabListView didChangeSelectedIndex:(NSUInteger)selectedIndex
{
    [self p_showViewControllerAtIndex:selectedIndex];
}

#pragma mark - notification

- (void)applicationDidChangeStatusBarFrameNotification:(NSNotification *)notification
{
    [self p_layoutViews];
}

- (void)applicationDidBecomeActiveNotification:(NSNotification *)notification
{
    [self p_layoutViews];
}

@end
