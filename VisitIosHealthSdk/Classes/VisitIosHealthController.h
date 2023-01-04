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

@interface VisitIosHealthController : WKWebView<WKScriptMessageHandler>{
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
    UIViewController *currentTopVC;
    UIViewController * addDependentViewController;
    UIView * addDependentTopBar;
    HKHealthStore *healthStore;
    UIActivityIndicatorView *activityIndicator;
    UIViewController* caller;
    BOOL fitbitConnectionTriggered;
}

@property (nonatomic, weak) VisitVideoCallDelegate* videoCallDelegate;
- (void) loadVisitWebUrl:(NSString*) magicLink;
- (void) initialParams:(NSDictionary *)params;
- (void) callHraApi;
- (void) urlOpened:(NSURL*) url;

@end

