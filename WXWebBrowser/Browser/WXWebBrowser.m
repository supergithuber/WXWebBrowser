//
//  WXWebBrowser.m
//  iOSDemo
//
//  Created by Wuxi on 2018/4/9.
//  Copyright © 2018年 Wuxi. All rights reserved.
//

#import "WXWebBrowser.h"
#import <WebKit/WebKit.h>
#import "WXWebBrowserScriptMeaasgeDelegate.h"

typedef NS_ENUM(NSUInteger, WXWebBrowserLoadType) {
    WXWebBrowserLoadTypeURLString,
    WXWebBrowserLoadTypeHTMLString,
    WXWebBrowserLoadTypePostURLString
};
static NSString *const kScriptMessageHandlerFirstKey = @"scriptMessageHandlerFirstKey";
static void *kProgressViewContext = &kProgressViewContext;

@interface WXWebBrowser ()<WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate>

@property (nonatomic, strong)WKWebView *wkWebView;
@property (nonatomic)UIBarButtonItem *backBarButtonItem;
@property (nonatomic)UIBarButtonItem *closeBarButtonItem;

@property (nonatomic, assign)WXWebBrowserLoadType loadType;
//仅当第一次的时候加载本地JS
@property (nonatomic,assign)BOOL needLoadJSPOST;
@property (nonatomic, copy)NSString *URLString;
@property (nonatomic, copy)NSString *postData;

@property (nonatomic, copy)NSString *remoteURL;

//进度条
@property (nonatomic, strong)UIProgressView *progressView;

@end

@implementation WXWebBrowser

- (void)dealloc {
    [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    //移除代理
    self.wkWebView.UIDelegate = nil;
    self.wkWebView.navigationDelegate = nil;
    //移除usercontent
    [self.wkWebView.configuration.userContentController removeScriptMessageHandlerForName:kScriptMessageHandlerFirstKey];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
    [self loadPages];
    [self updateNavigationItems];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (_isNavigationHidden){
        self.navigationController.navigationBarHidden = NO;
        //加一个自定义的状态栏
        UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, [[UIApplication sharedApplication] statusBarFrame].size.height)];
        statusBarView.backgroundColor=[UIColor whiteColor];
        [self.view addSubview:statusBarView];
    }else{
        self.navigationController.navigationBarHidden = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
- (void)setupView {
    [self.view addSubview:self.wkWebView];
    [self.view addSubview:self.progressView];
    
    UIBarButtonItem* reLoad = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(roadLoadClicked)];
    UIBarButtonItem* menuItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(menuClicked)];
    reLoad.tintColor = [UIColor blackColor];
    menuItem.tintColor = [UIColor blackColor];
    
    self.navigationItem.rightBarButtonItems = @[menuItem, reLoad];
}
- (void)loadPages {
    switch (self.loadType) {
        case WXWebBrowserLoadTypeURLString:{
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.URLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
            [self.wkWebView loadRequest:request];
            break;
        }
        case WXWebBrowserLoadTypeHTMLString:{
            [self loadHostPathURL:self.URLString];
            break;
        }
        case WXWebBrowserLoadTypePostURLString:{
            self.needLoadJSPOST = YES;
            [self loadHostPathURL:@"WKJSPOST"];
            break;
        }
        default:
            break;
    }
}
- (void)updateNavigationItems {
    if ([self.wkWebView canGoBack]){
        UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spaceButtonItem.width = -6.5;
        
        [self.navigationItem setLeftBarButtonItems:@[spaceButtonItem,self.backBarButtonItem,self.closeBarButtonItem] animated:NO];
    }else{
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:@[self.backBarButtonItem]];
    }
}
- (void)loadHostPathURL:(NSString *)url{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:url ofType:@"html"];
    NSString *html = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self.wkWebView loadHTMLString:html baseURL:[[NSBundle bundleForClass:[self class]] bundleURL]];  //baseURL:资源文件对应的路径，例如css、img、js，js文件要放到copy bundle resources中
}
- (void)postRequestWithJS {
    // 拼装成调用JavaScript的字符串
    NSString *jscript = [NSString stringWithFormat:@"post('%@',{%@});", self.URLString, self.postData];
//    NSString *newJSscript = [NSString stringWithFormat:@"alertAction('%@', '%@')", self.URLString, self.postData];
    // 调用JS代码
//    [self.wkWebView evaluateJavaScript:newJSscript completionHandler:^(id object, NSError * _Nullable error) {
//
//    }];
    [self.wkWebView evaluateJavaScript:jscript completionHandler:^(id object, NSError * _Nullable error) {
        
    }];
}
//MARK: - Action
- (void)roadLoadClicked {
    [self.wkWebView reload];
}

- (void)menuClicked {
    if (self.wkWebView.URL){
        UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[self.wkWebView.URL] applicationActivities:nil];
        [self presentViewController:controller animated:YES completion:^{
            
        }];
    }
}

- (void)closeWebview {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)backWebview {
    if (self.wkWebView.canGoBack){
        [self.wkWebView goBack];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}
//MARK: - public
- (void)loadRemoteURLString:(NSString *)URLString{
    self.URLString = URLString;
    self.loadType = WXWebBrowserLoadTypeURLString;
    
}
- (void)loadLocalHTMLString:(NSString *)string {
    self.URLString = string;
    self.loadType = WXWebBrowserLoadTypeHTMLString;
    
}
- (void)postWebURLSring:(NSString *)string postData:(NSString *)postData{
    self.URLString = string;
    self.postData = postData;
    self.loadType = WXWebBrowserLoadTypePostURLString;
}
- (void)snapShotRect:(CGRect)rect completion:(void(^)(UIImage*, NSError*))completion{
    if (@available(iOS 11.0, *)) {
        if (!CGRectEqualToRect(rect, CGRectZero)){
            WKSnapshotConfiguration *configuration = [WKSnapshotConfiguration new];
            configuration.rect = rect;
            [self.wkWebView takeSnapshotWithConfiguration:configuration completionHandler:^(UIImage * _Nullable snapshotImage, NSError * _Nullable error) {
                completion(snapshotImage, error);
            }];
        }else{
            [self.wkWebView takeSnapshotWithConfiguration:nil completionHandler:^(UIImage * _Nullable snapshotImage, NSError * _Nullable error) {
                completion(snapshotImage, error);
            }];
        }
        
    } else {
        NSError *error = [[NSError alloc] initWithDomain:@"com.wxwebbrowser" code:-999 userInfo:@{NSLocalizedDescriptionKey:@"ios11 available"}];
        completion(nil, error);
    }
    
}
//MARK: - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))]){
        [self.progressView setAlpha:1.0];
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        //加载完成消失
        if(self.wkWebView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
//MARK: - WKScriptMessageHandler
//当js端调用：window.webkit.messageHandlers.scriptMessageHandlerFirstKey.postMessage({body: '传数据'})的时候，会进入到这里，在这里可以调用oc方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    if ([message.name isEqualToString:kScriptMessageHandlerFirstKey]){
        NSLog(@"name:%@\\\\n body:%@\\\\n frameInfo:%@\\\\n",message.name,message.body,message.frameInfo);
    }
}
//MARK: - WKNavigationDelegate
//页面开始加载时
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    self.progressView.hidden = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewStarToLoad:)]){
        [self.delegate webViewStarToLoad:self];
    }
}
//当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    if (self.delegate && [self.delegate respondsToSelector:@selector(contentsStartToReturn:)]){
        [self.delegate contentsStartToReturn:self];
    }
}
//页面加载完成
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewLoadFinished:)]){
        [self.delegate webViewLoadFinished:self];
    }
    //当网页的内容全部显示（网页内的所有图片必须都正常显示）的时候调用（不是出现的时候就调用），部分显示时这个方法就不调用
    // 判断是否需要加载（仅在第一次加载）
    if (self.needLoadJSPOST) {
        // 调用使用JS发送POST请求的方法
        [self postRequestWithJS];
        // 将Flag置为NO（后面就不需要加载了）
        self.needLoadJSPOST = NO;
    }
    self.title = self.wkWebView.title;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateNavigationItems];
}
//页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:Loadfailed:)]){
        [self.delegate webView:self Loadfailed:error];
    }
    NSLog(@"页面加载失败%@", error);
}
//接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"收到服务器跳转请求");
}
//在收到响应后，决定是否跳转
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
//
//}
// 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    //可以依据:navigationAction.request.URL.host来决定是否要跳转
    NSLog(@"在发送请求之前，决定是否跳转");
    //有回退，刷新等
    switch (navigationAction.navigationType) {
        case WKNavigationTypeLinkActivated:
            break;
        default:
            break;
    }
    [self updateNavigationItems];
    decisionHandler(WKNavigationActionPolicyAllow);
}
//- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
//    // 判断服务器采用的验证方法
//    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust){
//        if (challenge.previousFailureCount == 0){
//            // 如果没有错误的情况下 创建一个凭证，并使用证书
//            NSURLCredential * credential = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
//            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
//
//        }else{
//            // 验证失败，取消本次验证
//            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
//        }
//    }else{
//        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
//    }
//}
//跳转失败的时候调用
-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"跳转失败%@", error);
}
//进度条结束
-(void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    
}

//MARK: - WKUIDelegate
// 在JS端调用alert函数时，会触发此代理方法。
// JS端调用alert时所传的数据可以通过message拿到
// 在原生得到结果后，需要回调JS，是通过completionHandler回调
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}
// JS端调用confirm函数时，会触发此方法
// 通过message可以拿到JS端所传的数据
// 在iOS端显示原生alert得到YES/NO后
// 通过completionHandler回调给JS端
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
}
// JS端调用prompt函数时，会触发此方法
// 要求输入一段文本
// 在原生输入得到文本内容后，通过completionHandler回调给JS
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"textinput" message:@"JS调用输入框" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

//MARK: - 一些懒加载
- (WKWebView *)wkWebView{
    if (!_wkWebView){
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
        configuration.allowsInlineMediaPlayback = YES;  //允许在线播放视频，用h5
        configuration.allowsPictureInPictureMediaPlayback = YES;   //是否允许画中画播放视频
        if (_applicationNameUserAgent){
            configuration.applicationNameForUserAgent = _applicationNameUserAgent;
        }
        configuration.allowsAirPlayForMediaPlayback = YES;  //是否允许AirPlay
        configuration.selectionGranularity = WKSelectionGranularityCharacter;  //选择粒度
        configuration.processPool = [WKProcessPool new];  //https://developer.apple.com/documentation/webkit/wkprocesspool
        configuration.suppressesIncrementalRendering = YES;  //（压制增量渲染）是否全部加载到内存里，才会去渲染
        //添加脚本信息处理者，需要实现WKScriptMessageHandler这个协议。代理不用self，用WXWebBrowserScriptMeaasgeDelegate，是为了解决不会释放的问题
        //WKUserContentController是用来给给JS注入对象的，之后JS端就可以使用
        //window.webkit.messageHandlers.scriptMessageHandlerFirstKey.postMessage({body: '传数据'})来传数据
        //传数据NSNumber, NSString, NSDate, NSArray,NSDictionary, and NSNull这些类型
        //JS调用完后，我们可以在代理里收到数据
        WKUserContentController *contentController = [[WKUserContentController alloc] init];
        configuration.userContentController = contentController;
        [configuration.userContentController addScriptMessageHandler:[[WXWebBrowserScriptMeaasgeDelegate alloc] initWithDelegate:self] name:kScriptMessageHandlerFirstKey];
        
        _wkWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        _wkWebView.UIDelegate = self;
        _wkWebView.navigationDelegate = self;
        _wkWebView.allowsBackForwardNavigationGestures = YES; //允许手势滑动前进后退
        [_wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:kProgressViewContext];
        _wkWebView.allowsBackForwardNavigationGestures = YES;  //手势触摸
        [_wkWebView sizeToFit];
    }
    return _wkWebView;
}
- (UIBarButtonItem *)backBarButtonItem {
    if (!_backBarButtonItem){
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [UIImage imageNamed:@"navigation-back" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        [backButton setImage:image forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(backWebview) forControlEvents:UIControlEventTouchUpInside];
        
        _backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    return _backBarButtonItem;
}
- (UIBarButtonItem *)closeBarButtonItem {
    if (!_closeBarButtonItem){
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [UIImage imageNamed:@"navigation-close" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
        [closeButton setImage:image forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(closeWebview) forControlEvents:UIControlEventTouchUpInside];
        
        _closeBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    }
    return _closeBarButtonItem;
}
- (UIProgressView *)progressView{
    if (!_progressView){
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        if (_isNavigationHidden){
            _progressView.frame = CGRectMake(0, [[UIApplication sharedApplication] statusBarFrame].size.height, self.view.bounds.size.width, 3);
        }else{
            _progressView.frame = CGRectMake(0, [[UIApplication sharedApplication] statusBarFrame].size.height + 44, self.view.bounds.size.width, 3);
        }
        // 设置进度条的色彩
        [_progressView setTrackTintColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0]];
        _progressView.progressTintColor = self.progressColor;
    }
    return _progressView;
}
- (UIColor *)progressColor{
    if (!_progressColor){
        _progressColor = [UIColor blueColor];
    }
    return _progressColor;
}
@end
