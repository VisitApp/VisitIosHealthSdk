//
//  ExternalViewController.h
//  Pods
//
//  Created by Yash on 01/11/23.
//

#ifndef ExternalViewController_h
#define ExternalViewController_h
#import <WebKit/WebKit.h>

@interface ExternalViewController : UIViewController<WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (strong, nonatomic) NSString *link;


@end

#endif /* ExternalViewController_h */
