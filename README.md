# VisitIosHealthSdk

[![CI Status](https://img.shields.io/travis/81799742/VisitIosHealthSdk.svg?style=flat)](https://travis-ci.org/81799742/VisitIosHealthSdk)
[![Version](https://img.shields.io/cocoapods/v/VisitIosHealthSdk.svg?style=flat)](https://cocoapods.org/pods/VisitIosHealthSdk)
[![License](https://img.shields.io/cocoapods/l/VisitIosHealthSdk.svg?style=flat)](https://cocoapods.org/pods/VisitIosHealthSdk)
[![Platform](https://img.shields.io/cocoapods/p/VisitIosHealthSdk.svg?style=flat)](https://cocoapods.org/pods/VisitIosHealthSdk)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- Supports iOS version >=13.0
- Please ensure that you have added permission texts for the following usages in your Info.plist file - Privacy - Health Share Usage Description, Privacy - Health Update Usage Description
- Add HealthKit in Signing & Capabilities
- The project needs to have cocoapods added to it. Please follow this [article](https://www.hackingwithswift.com/articles/95/how-to-add-cocoapods-to-your-project) to add cocoapods to your project.

## Installation

VisitIosHealthSdk is available through [Visit private pod spec](https://github.com/VisitApp/visit-ios-pod-spec). To install
it, add the following lines to the top of your Podfile:

```ruby
source 'https://github.com/VisitApp/visit-ios-pod-spec.git'
source 'https://github.com/CocoaPods/Specs.git'
```

Then, add the following line within the target in your Podfile:


```ruby
pod 'VisitIosHealthSdk'
```

## Usage

To use the SDK, you simply need to initialize VisitIosHealthController in your ViewController. Ensure that the initalized view is added to your main subview in viewDidLoad method. Once that is done call the loadVisitWebUrl method in viewDidAppear lifecycle method.

Here's an example code where the `VisitIosHealthController` is programmatically initialized -

```swift
//
//  ViewController.swift
//  VisitIosHealthSdk
//
//  Created by 81799742 on 01/24/2022.
//  Copyright (c) 2022 81799742. All rights reserved.
//

import UIKit
import VisitIosHealthSdk;

extension Notification.Name {
    static let customNotificationName = Notification.Name("VisitEventType")
}

class ViewController: UIViewController {

    let visitHealthView = VisitIosHealthController.init();
    let button = UIButton(frame: CGRect(x: 20, y: 20, width: 200, height: 60))
    let tataAIG_base_url = "tataAIG_base_url"
    let tataAIG_auth_token = "tataAIG_auth_token"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // show button programattically, in actual app this can be ignored
        self.showButton()

        // passing tataAIG_base_url and tataAIG_auth_token in form of a dictionary
        visitHealthView.initialParams(["tataAIG_base_url":tataAIG_base_url, "tataAIG_auth_token":tataAIG_auth_token])
        
        // adding observer to watch for events
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: .customNotificationName, object: nil)
        
    }
    
    @objc func showButton(){
        self.view.addSubview(button)
        button.center = CGPoint(x: view.frame.size.width  / 2, y: view.frame.size.height / 4)
        button.setTitle("Open Visit app", for: .normal)
        button.backgroundColor = .blue
        button.setTitleColor(UIColor.white, for: .normal)
        button.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
    }
    
    @objc func hideButton(){
        button.removeFromSuperview()
    }
    
    @objc func methodOfReceivedNotification(notification: Notification) {
        let event = notification.userInfo?["event"] as! String
        let current = notification.userInfo?["current"] ?? ""
        let total = notification.userInfo?["total"] ?? ""
        switch(event){
            case "HealthKitConnectedAndSavedInPWA":
                print("health kit connected and saved")
            case "AskForFitnessPermission":
                print("health kit permission requested")
            case "FitnessPermissionGranted":
                print("health kit permission granted")
            case "HRA_Completed":
                print("hra completed")
            case "HRAQuestionAnswered":
                print("HRAQuestionAnswered,",current,"of",total)
            case "ClosePWAEvent":
                // show initial button again, in actual app this can be ignored
                self.showButton();

            default:
                print("nothing")
        }
        print("method Received Notification",event)
    }
    
    @objc func buttonTapped(sender : UIButton) {
        // since both UIs share same view the button needs to be hidden, in actual app this can be ignored
        self.hideButton()
        
        // adding subview and loading url, below statements need to be called in same order
        visitHealthView.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(visitHealthView.view)
        visitHealthView.loadVisitWebUrl("magic_link",caller: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}



```

## Author

81799742, yash-vardhan@hotmail.com

## License

VisitIosHealthSdk is available under the MIT license. See the LICENSE file for more info.
