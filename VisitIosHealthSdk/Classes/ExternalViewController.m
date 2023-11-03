//
//  ExternalViewController.m
//  VisitIosHealthSdk
//
//  Created by Yash on 01/11/23.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "ExternalViewController.h"

@implementation ExternalViewController

// WKNavigationDelegate method to observe URL changes
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    NSLog(@"Current URL: in wkwebview %@", url.absoluteString);
    if([url.absoluteString containsString:@"tataaig.com"]){
        decisionHandler(WKNavigationActionPolicyCancel);
        self.webView.navigationDelegate = nil;
        self.webView.scrollView.delegate = nil;
        [self.webView stopLoading];
        [self removeFromParentViewController];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a WKWebView
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.webView];
    self.webView.navigationDelegate = self; // Set the navigation delegate
    self.view.translatesAutoresizingMaskIntoConstraints = false;
    
    // Load a URL
    NSString *urlString = _link;
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{@"view" : self.webView} ]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:@{@"view" : self.webView} ]];
}

@end
