//
//  BCOTabController.h
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/12.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCOTabColor.h"

@interface BCOTabController : UIViewController

@property (nonatomic, copy) NSArray *viewControllers;     // array of UIViewController
@property (nonatomic, copy) NSArray *tabColors;           // array of BCOTabColor

@property (nonatomic, readonly) UIViewController *selectedViewController;
@property (nonatomic) NSUInteger selectedIndex;

@end