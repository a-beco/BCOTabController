//
//  BCOTabListView.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOTabListView.h"
#import "BCOTabColor.h"
#import "BCOTabItem.h"

// タブ直下の線の幅
const NSUInteger kBCOTabListViewBottomBorderWidth = 5;

// タブの横幅
const CGFloat kBCOTabListViewTabWidth = 88;

// タブ間の間隔
const CGFloat kBCOTabListViewTabSpaceWidth = 5;

// あるタブの左端から次のタブの左端までの距離
const CGFloat kBCOTabListViewStepWidth = kBCOTabListViewTabWidth + kBCOTabListViewTabSpaceWidth;

// タブ上の間隔
const CGFloat kBCOTabListViewTabTopMargin = 5;


@interface BCOTabListView () <BCOTabItemDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) NSArray *tabItems;

@end

@implementation BCOTabListView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.showsHorizontalScrollIndicator = NO;
        [self addSubview:_scrollView];
        
        _borderView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:_borderView];
        [self p_updateBorderBackgroundColor];
        
        [self setNeedsLayout];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _scrollView.frame = CGRectMake(0,
                                   0,
                                   self.bounds.size.width,
                                   self.bounds.size.height - kBCOTabListViewBottomBorderWidth);
    
    _borderView.frame = CGRectMake(0,
                                   self.bounds.size.height - kBCOTabListViewBottomBorderWidth,
                                   self.bounds.size.width,
                                   kBCOTabListViewBottomBorderWidth);
}

#pragma mark - property

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self setNeedsLayout];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsLayout];
}

- (void)setTitles:(NSArray *)titles
{
    _titles = [titles copy];
    
    if (!_tabItems || [_tabItems count] != [_titles count]) {
        [self p_constractTabViews];
    }
    else {
        [self p_updateTitles];
    }
}

- (void)setTabColors:(NSArray *)tabColors
{
    _tabColors = [tabColors copy];
    
    [self p_updateColors];
    [self p_updateBorderBackgroundColor];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    _selectedIndex = selectedIndex;
    [self p_updateSelection];
    [self p_updateBorderBackgroundColor];
    [self p_moveToSelectionAnimated:YES];
}

#pragma mark - private

- (BCOTabColor *)p_defaultTabColor
{
    return [BCOTabColor tabColorWithBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]
                                          textColor:[UIColor colorWithWhite:0.2 alpha:1.0]
                         highlightedBackgroundColor:[UIColor colorWithWhite:0.4 alpha:1.0]
                               highlightedTextColor:[UIColor colorWithWhite:1.0 alpha:1.0]];
}

- (BCOTabColor *)p_tabColorAtIndex:(NSUInteger)index
{
    if (_tabColors && [_tabColors count] > index) {
        BCOTabColor *tabColor = _tabColors[index];
        if ([tabColor isKindOfClass:[BCOTabColor class]]) {
            return tabColor;
        }
    }
    return [self p_defaultTabColor];
}

- (void)p_constractTabViews
{
    NSMutableArray *tabItemsBuf = @[].mutableCopy;
    for (int i = 0; i < [_titles count]; i++) {
        CGRect tabFrame = CGRectMake(kBCOTabListViewStepWidth * i,
                                     kBCOTabListViewTabTopMargin,
                                     kBCOTabListViewTabWidth,
                                     self.bounds.size.height - kBCOTabListViewBottomBorderWidth - kBCOTabListViewTabTopMargin);
        BCOTabColor *tabColor = [self p_tabColorAtIndex:i];
        BCOTabItem *tabItem = [[BCOTabItem alloc] initWithFrame:tabFrame
                                                          title:_titles[i]
                                                          color:tabColor];
        tabItem.delegate = self;
        
        [_scrollView addSubview:tabItem];
        [tabItemsBuf addObject:tabItem];
    }
    self.tabItems = [tabItemsBuf copy];
    
    [self p_updateBorderBackgroundColor];
    [self p_updateSelection];
    _scrollView.contentSize = CGSizeMake(kBCOTabListViewStepWidth * _titles.count - kBCOTabListViewTabSpaceWidth,
                                         _scrollView.bounds.size.height);
}

- (void)p_updateTitles
{
    for (int i = 0; i < [_tabItems count]; i++) {
        if ([_titles count] > i) {
            BCOTabItem *aTabItem = _tabItems[i];
            aTabItem.title = _titles[i];
        }
    }
}

- (void)p_updateColors
{
    for (int i = 0; i < [_tabItems count]; i++) {
        BCOTabItem *aTabItem = _tabItems[i];
        if ([_tabColors count] > i) {
            aTabItem.color = _tabColors[i];
        }
        else {
            aTabItem.color = [self p_defaultTabColor];
        }
    }
}

- (void)p_updateBorderBackgroundColor
{
    BCOTabColor *tabColor = nil;
    if (_tabColors && [_tabColors count] > _selectedIndex) {
        tabColor = _tabColors[_selectedIndex];
    }
    else {
        tabColor = [self p_defaultTabColor];
    }
    
    _borderView.backgroundColor = tabColor.highlightedBackgroundColor;
}

- (void)p_updateSelection
{
    if (!_tabItems || [_tabItems count] == 0) {
        return;
    }
    
    for (BCOTabItem *tabItem in _tabItems) {
        [tabItem setHighlighted:NO animated:YES];
    }
    
    BCOTabItem *selectedTabItem = nil;
    if ([_tabItems count] <= _selectedIndex) {
        _selectedIndex = 0;
    }
    
    selectedTabItem = _tabItems[_selectedIndex];
    [selectedTabItem setHighlighted:YES animated:YES];
}

- (void)p_moveToSelectionAnimated:(BOOL)animated
{
    BCOTabItem *tabItem = nil;
    if ([_tabItems count] > _selectedIndex) {
        tabItem = _tabItems[_selectedIndex];
    }
    
    CGFloat xOffset = tabItem.center.x - self.bounds.size.width / 2;
    CGFloat maxOffset = _scrollView.contentSize.width - self.bounds.size.width;
    if (xOffset < 0) {
        xOffset = 0;
    }
    else if (xOffset > maxOffset) {
        xOffset = maxOffset;
    }
    [_scrollView setContentOffset:CGPointMake(xOffset, 0) animated:animated];
}

#pragma mark - delegate

- (void)tabItemDidTap:(BCOTabItem *)tabItem
{
    NSUInteger tappedIndex = [_tabItems indexOfObject:tabItem];
    self.selectedIndex = tappedIndex;
    
    if ([_delegate respondsToSelector:@selector(tabListView:didTapIndex:)]) {
        [_delegate tabListView:self didTapIndex:_selectedIndex];
    }
}

@end
