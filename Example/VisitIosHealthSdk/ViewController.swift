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
    var button2Title: String = ""
    var isHealthKitConnected = false;
    
    let button = UIButton(frame: CGRect(x: 20, y: 20, width: 200, height: 60))
    let button2 = UIButton(frame: CGRect(x: 20, y: 40, width: 200, height: 60))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // modal implementation
        // visitHealthView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
        // vc.view = visitHealthView
        
        // OPTIONAL : the health kit permission status can be obtained using the following callback
        visitHealthView.canAccessHealthKit{(value) -> () in
            if(value){
                self.isHealthKitConnected = true;
                DispatchQueue.main.async {
                    self.showButton()
                }
                print("health kit can be accessed")
            }else{
                self.isHealthKitConnected = false;
                DispatchQueue.main.async {
                    self.showButton()
                }
                print("health kit can't be accessed")
            }
        }

        // show button programattically, in actual app this can be ignored

        
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
        let reason = notification.userInfo?["reason"] ?? ""
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
                print("visitCallback triggered,", message)
            case "NetworkError":
                print("NetworkError triggered,", message, code)

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
        let external_api_base_url = "https://uathealthvas.tataaig.com"
        let external_api_base_url_auth_token = "Basic Z2V0X3Zpc2l0OkZoNjh2JHdqaHU4WWd3NiQ="
        
        
        // OPTIONAL : syncing is enabled by default but it can be toggled using this method
        visitHealthView.setSyncingEnabled(true)
        
        // passing tataAIG_base_url and tataAIG_auth_token in form of a dictionary
        visitHealthView.initialParams(["tataAIG_base_url":external_api_base_url, "tataAIG_auth_token":external_api_base_url_auth_token]);
        
        // modal implementation
        // self.present(vc, animated: true)

        // subview implementation
        self.view.addSubview(visitHealthView)
        visitHealthView.translatesAutoresizingMaskIntoConstraints = false
        
        visitHealthView.loadVisitWebUrl("--magic-link--")

        // subview implementation
        let views = ["view" : visitHealthView]
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[view]|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: views))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

