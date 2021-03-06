//
//  WXWebBrowser.h
//  iOSDemo
//
//  Created by Wuxi on 2018/4/9.
//  Copyright © 2018年 Wuxi. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WXWebBrowser;
@protocol WXWebBrowserProtocol<NSObject>

@optional
- (void)webViewStarToLoad:(WXWebBrowser *)webBrowser;//页面开始加载
- (void)contentsStartToReturn:(WXWebBrowser *)webBrowser;//内容开始返回
- (void)webViewLoadFinished:(WXWebBrowser *)webBrowser;//内容加载完成
- (void)webView:(WXWebBrowser *)webBrowser Loadfailed:(NSError *)error;//页面加载失败

@end

@interface WXWebBrowser : UIViewController

@property (nonatomic, assign)BOOL isNavigationHidden;
@property (nonatomic, strong)UIColor *progressColor;
@property (nonatomic, copy)NSString *applicationNameUserAgent;   //请求头中APP名字的User-Agent中的信息

@property (nonatomic, weak)id<WXWebBrowserProtocol> delegate;


/**
 加载远程链接

 @param URLString 远程URLString
 */
- (void)loadRemoteURLString:(NSString *)URLString;

/**
 加载本地html文件

 @param string 本地html文件名，需要把文件放在bundle中，后缀是html
 */
- (void)loadLocalHTMLString:(NSString *)string;
/**
 1. 加载外部链接POST请求,本质上是通过先加载本地的一个html，在finish的时候注入以下数据，所以本地需要一个文件WKJSPOST.html
 2. postData请求块 注意格式：@"\"username\":\"xxxx\",\"password\":\"xxxx\""
 3. 在js里添加了支持弹窗的script，postData格式：@"你要显示的信息"  (先关闭)
 
 @param string 需要POST的URL地址
 @param postData post请求块
 */
- (void)postWebURLSring:(NSString *)string postData:(NSString *)postData;

//help function

/**
 snapShot image, @available ios 11
 @param rect pass CGRectZero for full ios screen
 */
- (void)snapShotRect:(CGRect)rect completion:(void(^)(UIImage*, NSError*))completion;

@end
