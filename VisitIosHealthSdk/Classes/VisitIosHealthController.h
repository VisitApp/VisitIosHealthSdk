//
//  ViewController.h
//  ios-health
//
//  Created by Yash on 18/01/22.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <HealthKit/HealthKit.h>
#import "VisitVideoCallDelegate.h"

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
    UIViewController * addDependentViewController;
    UIView * addDependentTopBar;
    HKHealthStore *healthStore;
    WKWebView *webView;
    UIActivityIndicatorView *activityIndicator;
    UIViewController* caller;
}

@property (nonatomic, weak) VisitVideoCallDelegate* videoCallDelegate;
- (void) loadVisitWebUrl:(NSString*) magicLink caller:(UIViewController*) caller;
- (void) initialParams:(NSDictionary *)params;
- (void) callHraApi;

@end

