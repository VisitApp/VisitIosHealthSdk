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
- In Signing & Capabilities add HealthKit


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
import UIKit
import VisitIosHealthSdk;

class ViewController: UIViewController {
    let visitHealthView = VisitIosHealthController.init();
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(visitHealthView.view)
        visitHealthView.view.translatesAutoresizingMaskIntoConstraints = false
    }
    override func viewDidAppear(_ animated: Bool) {
        visitHealthView.loadVisitWebUrl( magic_link,caller: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

```

## Author

81799742, yash-vardhan@hotmail.com

## License

VisitIosHealthSdk is available under the MIT license. See the LICENSE file for more info.
