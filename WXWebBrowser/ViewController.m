//
//  ViewController.m
//  WXWebBrowser
//
//  Created by HFY on 2018/7/2.
//  Copyright © 2018年 wuxi. All rights reserved.
//

#import "ViewController.h"
#import "WXWebBrowser.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)openWebview:(UIButton *)sender {
    WXWebBrowser *webView = [WXWebBrowser new];
    [webView loadRemoteURLString:@"https://www.baidu.com"];
    [self.navigationController pushViewController:webView animated:true];
}


@end
