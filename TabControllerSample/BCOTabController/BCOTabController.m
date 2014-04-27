//
//  BCOTabController.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/12.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOTabController.h"
#import "BCOPageController.h"
#import "BCOTabListView.h"


const CGFloat kBCOTabControllerStatusBarHeight = 20.0;
const CGFloat kBCOTabControllerTabListViewHeight = 50.0;
NSString * const kViewControllerTitleKey = @"title";

@interface BCOTabController () <BCOTabListViewDelegate,
                                BCOPageControllerDelegate,
                                BCOPageControllerDataSource>

@property (nonatomic, strong) BCOPageController *pageController;
@property (nonatomic, strong) BCOTabListView *tabListView;

@end


@implementation BCOTabController

@dynamic tabColors;
@dynamic selectedIndex;

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
    self.view.backgroundColor = [UIColor whiteColor];
    
    // notifications
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self p_removeViewControllerKVO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // サブビューを作成
    _tabListView = [[BCOTabListView alloc] initWithFrame:CGRectZero];
    _tabListView.delegate = self;
    [self.view addSubview:_tabListView];
    
    _pageController = [[BCOPageController alloc] init];
    _pageController.delegate = self;
    _pageController.dataSource = self;
    [self.view addSubview:_pageController.view];
    [self addChildViewController:_pageController];
    
    // サブビューをレイアウト
    [self p_layoutViews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - property

- (void)setViewControllers:(NSArray *)viewControllers
{
    [self p_removeViewControllerKVO];
    
    _viewControllers = [viewControllers copy];
    [self p_updateTabListTitles];
    
    [self p_showViewControllerAtIndex:self.selectedIndex];
    [self p_addViewControllersKVO];
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
                                    kBCOTabControllerStatusBarHeight,
                                    self.view.bounds.size.width,
                                    kBCOTabControllerTabListViewHeight);
    
    CGFloat containerY = _tabListView.frame.origin.y + _tabListView.frame.size.height;
    _pageController.view.frame = CGRectMake(0,
                                            containerY,
                                            self.view.bounds.size.width,
                                            self.view.bounds.size.height - containerY);
}

- (void)p_showViewControllerAtIndex:(NSUInteger)index
{
    if (!_viewControllers || [_viewControllers count] == 0) {
        return;
    }
    
    if ([_viewControllers count] <= index) {
        index = 0;
    }
    
    _pageController.selectedIndex = index;
}

- (NSArray *)p_viewControllerTitles
{
    NSMutableArray *titlesBuf = @[].mutableCopy;
    for (UIViewController *vc in _viewControllers) {
        [titlesBuf addObject:vc.title];
    }
    return [titlesBuf copy];
}

- (void)p_addViewControllersKVO
{
    for (UIViewController *vc in _viewControllers) {
        [vc addObserver:self
             forKeyPath:kViewControllerTitleKey
                options:NSKeyValueObservingOptionNew
                context:nil];
    }
}

- (void)p_removeViewControllerKVO
{
    for (UIViewController *vc in _viewControllers) {
        [vc removeObserver:self forKeyPath:kViewControllerTitleKey];
    }
}

- (void)p_updateTabListTitles
{
    _tabListView.titles = [self p_viewControllerTitles];
}

#pragma mark - BCOTabListView delegate

- (void)tabListView:(BCOTabListView *)tabListView didTapIndex:(NSUInteger)selectedIndex
{
    [self p_showViewControllerAtIndex:selectedIndex];
}

#pragma mark - BCOPageController delegate

- (void)pageController:(BCOPageController *)pageController didMoveToIndex:(NSUInteger)index
{
    _tabListView.selectedIndex = index;
}

#pragma mark - BCOPageController dataSource

- (UIViewController *)pageController:(BCOPageController *)pageController pageForIndex:(NSUInteger)index
{
    if (index >= [_viewControllers count]) {
        return nil;
    }
    
    return _viewControllers[index];
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

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kViewControllerTitleKey]) {
        [self p_updateTabListTitles];
    }
}

@end
