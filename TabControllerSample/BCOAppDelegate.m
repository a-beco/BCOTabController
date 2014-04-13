//
//  BCOAppDelegate.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/12.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOAppDelegate.h"
#import "BCOTabController.h"
#import "BCOTabInfoManager.h"

@implementation BCOAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // 表示するViewControllerを用意
    NSArray *colors = @[[UIColor redColor], [UIColor yellowColor], [UIColor blueColor], [UIColor greenColor], [UIColor purpleColor]];
    
    NSMutableArray *viewControllersBuf = @[].mutableCopy;
    NSArray *titles = [BCOTabInfoManager sharedManager].allTitles;
    for (int i = 0; i < [titles count]; i++) {
        NSString *title = titles[i];
        UIViewController *vc = [[UIViewController alloc] init];
        vc.title = title;
        vc.view.backgroundColor = colors[i];
        [viewControllersBuf addObject:vc];
    }
    
    // タブコントローラを作ってセット
    self.tabController = [[BCOTabController alloc] init];
    _tabController.viewControllers = [viewControllersBuf copy];
    _tabController.tabColors = [BCOTabInfoManager sharedManager].allColors;
    
    self.window.rootViewController = _tabController;
    [self.window makeKeyAndVisible];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
