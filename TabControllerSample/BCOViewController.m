//
//  BCOViewController.m
//  TabControllerSample
//
//  Created by 阿部耕平 on 2014/04/12.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOViewController.h"
#import "BCOTabController.h"
#import "BCOTabInfoManager.h"

@interface BCOViewController ()
@property (nonatomic, strong) UIWebView *webView;
@end

@implementation BCOViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_webView];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://google.com"]];
    [_webView loadRequest:request];
}

- (void)viewDidAppear:(BOOL)animated
{
    _webView.frame = self.view.bounds;
    
    if ([self.title isEqualToString:@"tab3"]) {
        self.title = @"abc";
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
