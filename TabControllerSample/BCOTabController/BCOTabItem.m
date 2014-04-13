//
//  BCOTabItem.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/13.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOTabItem.h"
#import "BCOTabColor.h"

@interface BCOTabItem ()

@property (nonatomic, strong) UILabel *titleLabel;

@end

const CGFloat kBCOTabItemDefaultTitleFontSize = 14;
const NSTimeInterval kBCOTabItemColorAnimationDuration = 0.17;

@implementation BCOTabItem

- (id)initWithFrame:(CGRect)frame
              title:(NSString *)title
              color:(BCOTabColor *)color
{
    self = [super initWithFrame:frame];
    if (self) {
        _title = [title copy];
        _color = [color copy];
        
        // view
        _titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _titleLabel.text = _title;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:kBCOTabItemDefaultTitleFontSize];
        [self addSubview:_titleLabel];
        
        [self p_updateColors];
        
        // gesture
        UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(tap:)];
        [self addGestureRecognizer:gr];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _titleLabel.frame = self.bounds;
}

#pragma mark - property

- (void)setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted;
    [self p_updateColors];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    _highlighted = highlighted;
    
    if (animated) {
        [UIView animateWithDuration:kBCOTabItemColorAnimationDuration animations:^{
            [self p_updateColors];
        }];
    }
    else {
        [self p_updateColors];
    }
}

#pragma mark - action

- (void)tap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if ([_delegate respondsToSelector:@selector(tabItemDidTap:)]) {
        [_delegate tabItemDidTap:self];
    }
}

#pragma mark - private

- (void)p_updateColors
{
    if (_highlighted) {
        self.backgroundColor = _color.highlightedBackgroundColor;
        _titleLabel.textColor = _color.highlightedTextColor;
    }
    else {
        self.backgroundColor = _color.backgroundColor;
        _titleLabel.textColor = _color.textColor;
    }
}

@end
