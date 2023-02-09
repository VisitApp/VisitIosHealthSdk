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

// extend VisitVideoCallDelegate if the video calling feature needs to be integrated otherwise UIViewController can be used
class ViewController: VisitVideoCallDelegate {
    // required
    let visitHealthView = AppDelegate.shared().visitHealthView
    
    // initializing a view controller which would be presented
    let vc = UIViewController()
    
    let button = UIButton(frame: CGRect(x: 20, y: 20, width: 200, height: 60))
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // modal implementation
        visitHealthView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
        vc.view = visitHealthView

        // subview implementation
        // let views = ["view" : visitHealthView]
        // vc.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[view]|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views))
        // vc.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: views))
        
        // show button programattically, in actual app this can be ignored
        self.showButton()
        
        // the notification observer
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: .customNotificationName, object: nil)
        
    }
    
    // show button programattically, in actual app this can be ignored
    @objc func showButton(){
        self.view.addSubview(button)
        button.center = CGPoint(x: view.frame.size.width  / 2, y: view.frame.size.height / 4)
        button.setTitle("Open Visit app", for: .normal)
        button.backgroundColor = .blue
        button.setTitleColor(UIColor.white, for: .normal)
        button.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
        
    }
    
    // hide button programattically, in actual app this can be ignored
    @objc func hideButton(){
        button.removeFromSuperview()
    }
    
    // notification observer
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
            case "FitbitPermissionGranted":
                print("Fitbit permission granted")
            case "FibitDisconnected":
                print("Fitbit permission revoked")
            case "HRA_Completed":
                print("hra completed")
            case "StartVideoCall":
                print("start video call")
            case "HRAQuestionAnswered":
                print("HRAQuestionAnswered,",current,"of",total)
            case "couponRedeemed":
                print("couponRedeemed triggered")
                
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
        
        
        // OPTIONAL : syncing is enabled by default but it can be toggled using this method
        visitHealthView.setSyncingEnabled(true)

            // modal implementation
            self.present(vc, animated: true)

//        self.view.addSubview(visitHealthView)
//        visitHealthView.translatesAutoresizingMaskIntoConstraints = false

        
        
        visitHealthView.loadVisitWebUrl("https://tata-aig.getvisitapp.xyz/sso?userParams=LH53MbTMvD-UcbZxap-i6S-h-D2Y0JgBpwJdDPhiJGglt2TtB7rOGM6_5Pe47zr_U6HkbChvwOkquwDooQRsynxJPzmfvaEWy3-lrXrKHsOCYi2-ViIMXSG6Q4WMD-O9xzjF2QiQkFghTInA8c5JX61MgSqsQoh-J4O9QeWF5b8IWqB8O8dBhOBOJ2GW4xaVQOuly1pQGRsiT4vmmHFlEANQkVxDFG5c_VjeTcVU-0BnkolpS7_iUAPxIyTc97LjJeNlEy9zsko-BrXlbKBn8S0uWnhDRQcI2A240DFR5oTxgJajUvZuaqE4fIzvSX9oE1WighSTWVuUWGoYVvvR1w&clientId=tata-aig-a8b455")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

