# VisitIosHealthSdk

[![CI Status](https://img.shields.io/travis/81799742/VisitIosHealthSdk.svg?style=flat)](https://travis-ci.org/81799742/VisitIosHealthSdk)
[![Version](https://img.shields.io/cocoapods/v/VisitIosHealthSdk.svg?style=flat)](https://cocoapods.org/pods/VisitIosHealthSdk)
[![License](https://img.shields.io/cocoapods/l/VisitIosHealthSdk.svg?style=flat)](https://cocoapods.org/pods/VisitIosHealthSdk)
[![Platform](https://img.shields.io/cocoapods/p/VisitIosHealthSdk.svg?style=flat)](https://cocoapods.org/pods/VisitIosHealthSdk)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- Supports iOS version >=13.0
- Please ensure that you have added permission texts for the following usages in your Info.plist file - Privacy - Health Share Usage Description, Privacy - Health Update Usage Description, Privacy - Camera Usage Description, Privacy - Local Network Usage Description, Privacy - Microphone Usage Description
- Add HealthKit in Signing & Capabilities
- Enable the "Background modes" capability for Audio, Airplay, and Picture in Picture in your Signings and Capabilites tab for your target
- The project needs to have cocoapods added to it. Please follow this [article](https://www.hackingwithswift.com/articles/95/how-to-add-cocoapods-to-your-project) to add cocoapods to your project.

## Installation

VisitIosHealthSdk is available through [Visit private pod spec](https://github.com/VisitApp/visit-ios-pod-spec). To install
it, add the following lines to the top of your Podfile:

```ruby
source 'https://github.com/VisitApp/visit-ios-pod-spec.git'
source 'https://cdn.cocoapods.org/'
```

Then, add the following line within the target in your Podfile:


```ruby
pod 'VisitIosHealthSdk'
```

## Usage

To use the SDK, you simply need to initialize VisitIosHealthController in your AppDelegate, and import this view inside your view controller. Ensure that the initalized view is added to your main subview in viewDidLoad method. Once that is done call the loadVisitWebUrl method.

Here's an example code where the `VisitIosHealthController` is programmatically initialized -

```swift
//  AppDelegate.swift
import UIKit
import VisitIosHealthSdk

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // add VisitSDK notification in the delegate's open method like below
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        NotificationCenter.default.post(name: Notification.Name("VisitSDK"), object: nil, userInfo: ["deepLink":url])
        return true
    }

    // add the shared static method like below to import visitHealthView in your view controller
    static func shared() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
}


//  ViewController.swift
import UIKit
import VisitIosHealthSdk;

extension Notification.Name {
    static let customNotificationName = Notification.Name("VisitEventType")
}

// extend VisitVideoCallDelegate if the video calling feature needs to be integrated otherwise UIViewController can be used
class ViewController: VisitVideoCallDelegate {
    // required
    let visitHealthView = AppDelegate.shared().visitHealthView

    // initializing a viewcontroller vc
    let vc = UIViewController()
    var button2Title: String = ""
    var isHealthKitConnected = false;
    
    let button = UIButton(frame: CGRect(x: 20, y: 20, width: 200, height: 60))
    let button2 = UIButton(frame: CGRect(x: 20, y: 40, width: 200, height: 60))

    override func viewDidLoad() {
        super.viewDidLoad()

        // OPTIONAL : the health kit permission status can be obtained using the following callback
        visitHealthView.canAccessHealthKit{(value) -> () in
            if(value){
                print("health kit can be accessed")
            }else{
                print("health kit can't be accessed")
            }
        }

        // intializing visitHealthView's frame
        visitHealthView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)

        // initializing vc's view with visitHealthView
        vc.view = visitHealthView
        
        // show button programattically, in actual app this can be ignored
        self.showButton()
        
        // the notification observer
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: .customNotificationName, object: nil)
    }
    
    // show button programattically, in actual app this can be ignored
    @objc func showButton(){
       button.center = CGPoint(x: view.frame.size.width  / 2, y: view.frame.size.height / 4)
        button.setTitle("Open Visit app", for: .normal)
        button.backgroundColor = .blue
        button.setTitleColor(UIColor.white, for: .normal)
        button.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
        self.view.addSubview(button)

        button2Title = visitHealthView.canAccessFitbit() ? "Disconnect from Fitbit" : "Connect to Fitbit"
        button2.center = CGPoint(x: view.frame.size.width  / 2, y: view.frame.size.height / 3)
        button2.setTitle(button2Title, for: .normal)
        button2.backgroundColor = .blue
        button2.setTitleColor(UIColor.white, for: .normal)
        button2.addTarget(self, action: #selector(self.button2Tapped), for: .touchUpInside)

        if(!self.isHealthKitConnected){
            self.view.addSubview(button2)
        }
    }
    
    // hide button programattically, in actual app this can be ignored
    @objc func hideButton(){
        button.removeFromSuperview()
        button2.removeFromSuperview()
    }

    @objc func button2Tapped(sender : UIButton) {
        if(visitHealthView.canAccessFitbit()){
            visitHealthView.revokeFitbitPermissions()
            self.hideButton()
        }else{
            self.buttonTapped(sender: sender)
        }
    }
    
   // notification observer
    @objc func methodOfReceivedNotification(notification: Notification) {
        let event = notification.userInfo?["event"] as! String
        let current = notification.userInfo?["current"] ?? ""
        let total = notification.userInfo?["total"] ?? ""
        let message = notification.userInfo?["message"] ?? ""
        let code = notification.userInfo?["code"] ?? ""
        switch(event){
            case "HealthKitConnectedAndSavedInPWA":
                print("health kit connected and saved")
            case "AskForFitnessPermission":
                print("health kit permission requested")
            case "FitnessPermissionGranted":
                print("health kit permission granted")
            case "FitbitPermissionGranted":
                print("Fitbit permission granted")
            case "FibitDisconnected":
                DispatchQueue.main.async {
                   self.showButton()
                }
                print("Fitbit permission revoked")
            case "HRA_Completed":
                print("hra completed")
            case "StartVideoCall":
                print("start video call")
            case "HRAQuestionAnswered":
                print("HRAQuestionAnswered,",current,"of",total)
            case "couponRedeemed":
                print("couponRedeemed triggered")
            case "EnableSyncing":
                print("EnableSyncing triggered")
            case "DisableSyncing":
                print("DisableSyncing triggered")
            case "consultationBooked":
                print("consultationBooked triggered")
            case "visitCallback":
                print("visitCallback triggered,", message, reason)
            case "NetworkError":
                print("NetworkError triggered,", message, code)
            case "VisitAnalyticsEvent":
                let eventName = notification.userInfo?["eventName"] ?? ""
                let properties = notification.userInfo?["properties"] ?? [:]
                print("VisitAnalyticsEvent triggered,", eventName, properties)

            case "ClosePWAEvent":
                // show initial button again, in actual app this can be ignored
                self.showButton();
                self.dismiss(animated: true)

            default:
                print("nothing")
        }
        print("method Received Notification",event)
    }
    
    @objc func buttonTapped(sender : UIButton) {
        // since both UIs share same view the button needs to be hidden, in actual app this can be ignored
        self.hideButton()
        let external_api_base_url = "--external_api_base_url--"
        let external_api_base_url_auth_token = "--external_api_base_url_auth_token--"
        
        
        // OPTIONAL : syncing is enabled by default but it can be toggled using this method
        visitHealthView.setSyncingEnabled(true)
        
        // passing tataAIG_base_url and tataAIG_auth_token in form of a dictionary
        visitHealthView.initialParams(["tataAIG_base_url":external_api_base_url, "tataAIG_auth_token":external_api_base_url_auth_token]);
        
        // modal implementation
        self.present(vc, animated: true)
        
        visitHealthView.loadVisitWebUrl("--magic-link--")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
```

## VisitAnalyticsEvent (PWA analytics bridge)

The PWA can forward analytics events to the native host app through the `visitIosView` JavaScript bridge. The SDK receives a `VISIT_EVENT` message and posts a `VisitAnalyticsEvent` notification that your app can observe.

The bridge accepts **both** payload formats: a JavaScript object (`postMessage({ ... })`) or a JSON string (`postMessage(JSON.stringify({ ... }))`).

### Web (PWA) — send an event

```javascript
const pushVisitEvent = (eventName, props) => {
  if (window.Android?.visitEvent) {
    window.Android.visitEvent(
      eventName,
      props == null ? null : JSON.stringify(props)
    );
    return;
  }

  const payload = {
    method: 'VISIT_EVENT',
    eventName,
    ...(props != null ? { props } : {})
  };

  if (window.webkit?.messageHandlers?.visitIosView) {
    window.webkit.messageHandlers.visitIosView.postMessage(payload);
  }
};

// Example
pushVisitEvent('screen_view', { screen: 'manual_sync' });
```

### iOS — receive the event

Listen for the existing `VisitEventType` notification and handle the `VisitAnalyticsEvent` case. Forward `eventName` and `properties` to your analytics SDK (Firebase, Mixpanel, etc.) as needed.

```swift
case "VisitAnalyticsEvent":
    let eventName = notification.userInfo?["eventName"] as? String ?? ""
    let properties = notification.userInfo?["properties"] as? [String: Any] ?? [:]
    // Forward to your analytics provider
    print("VisitAnalyticsEvent:", eventName, properties)
```

| Notification key | Type | Description |
|---|---|---|
| `event` | `String` | Always `"VisitAnalyticsEvent"` |
| `eventName` | `String` | Event name from the PWA |
| `properties` | `[String: Any]` | Optional event properties (only present when the PWA sends `props`) |

## Manual step sync

The PWA can trigger a manual HealthKit steps/calories sync for a selected date range. The SDK reads hourly steps and calories from HealthKit, then posts them to the `/fitness-activity` API using the same flow as automatic sync (`callUatApi`).

The bridge accepts **both** a JavaScript object and a `JSON.stringify` string for the message body.

### Web (PWA) — start manual sync

Post a message to `visitIosView` with `method` or `action` set to `initializeManualSync`, plus `startDate` and `endDate` in `yyyy-MM-dd` format.

```javascript
window.webkit.messageHandlers.visitIosView.postMessage({
  method: 'initializeManualSync', // `action` is also supported
  startDate: '2026-06-25',
  endDate: '2026-06-26'
});
```

### Native flow

1. Validates the date range and checks HealthKit permission.
2. Calls `window.syncingInProgress()` in the WebView when sync starts.
3. Fetches HealthKit data and syncs via `/fitness-activity`.
4. Calls one of the completion callbacks below when finished.

### Web (PWA) — sync status callbacks

Implement these on `window` in the PWA to update the sync UI:

```javascript
window.syncingInProgress = () => {
  // Show loading / syncing state
};

window.syncingCompleted = () => {
  // Hide loading, show success
};

window.syncingFailed = () => {
  // Hide loading, show error
};
```

### Requirements

- HealthKit read permission must be granted; otherwise `window.syncingFailed()` is called.
- Call `initialParams` with `tataAIG_base_url` and `tataAIG_auth_token` before syncing so the fitness-activity API can be authenticated.
- `memberId` must be available (set via `updateApiBaseUrlV2` from the PWA) for the sync payload.

### iOS notification (optional)

Manual sync does not post a separate native notification. Use the JavaScript callbacks above in the PWA, or listen for `visitCallback` notifications if the fitness-activity API reports success or failure.

## Author

81799742, gaurav.kumar@getvisitapp.com

## License

VisitIosHealthSdk is available under the MIT license. See the LICENSE file for more info.
