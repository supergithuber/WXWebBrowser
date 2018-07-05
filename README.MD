## WXWebBrowser

### interface

#### 1. load remote url 

``` objectivec
/**
 load remote url

 @param URLString remote URLString
 */
- (void)loadRemoteURLString:(NSString *)URLString;
```

#### 2. load local html

```objectivec
/**
 load local html file

 @param string filename，be required to be stored in mainBundle，with html suffix
 */
- (void)loadLocalHTMLString:(NSString *)string;
```

#### 3. inject a js to remote url

```objectivec
- (void)postWebURLSring:(NSString *)string postData:(NSString *)postData;

```