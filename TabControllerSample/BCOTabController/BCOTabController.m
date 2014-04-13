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


const CGFloat BCOTabControllerStatusBarHeight = 20.0;
const CGFloat BCOTabControllerTabListViewHeight = 44.0;

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
    _viewControllers = [viewControllers copy];
    _tabListView.titles = [self p_viewControllerTitles];
    
    [self p_showViewControllerAtIndex:self.selectedIndex];
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

@end
