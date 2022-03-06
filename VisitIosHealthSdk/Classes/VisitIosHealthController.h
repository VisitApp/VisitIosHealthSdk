//
//  ViewController.h
//  ios-health
//
//  Created by Yash on 18/01/22.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <HealthKit/HealthKit.h>

@interface VisitIosHealthController : UIViewController<WKScriptMessageHandler>{
    // Member variables go here.
    NSString *baseUrl;
    NSString *token;
    NSString *memberId;
    NSTimeInterval gfHourlyLastSync;
    NSTimeInterval googleFitLastSync;
    NSCalendar* calendar;
    NSString *gender;
    NSString *tataAIG_base_url;
    NSString *tataAIG_auth_token;
    NSUInteger bmrCaloriesPerHour;
    UIStoryboard* storyboard;
    UIViewController * sbViewController;
    HKHealthStore *healthStore;
    WKWebView *webView;
    UIActivityIndicatorView *activityIndicator;
    UIViewController* caller;
}

- (void)loadVisitWebUrl:(NSString*) magicLink caller:(UIViewController*) caller;
- (void) initialParams:(NSDictionary *)params;

@end

