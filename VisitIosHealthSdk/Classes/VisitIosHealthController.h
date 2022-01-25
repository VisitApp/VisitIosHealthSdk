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
    NSCalendar* calendar;
    NSString *gender;
    NSUInteger bmrCaloriesPerHour;
    HKHealthStore *healthStore;
    UIViewController * storyboardVC;
    WKWebView *webView;
    UIActivityIndicatorView *activityIndicator;
    BOOL hasLoadedOnce;
}
//@property (nonatomic, retain) UIViewController * viewController;
- (void)loadVisitWebUrl:(NSString *) baseUrl magicLink:(NSString*) magicLink caller:(UIViewController*) caller;
@end

