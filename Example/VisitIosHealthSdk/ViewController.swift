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

    let visitHealthView = VisitIosHealthController.init();
    let button = UIButton(frame: CGRect(x: 20, y: 20, width: 200, height: 60))
    let button2 = UIButton(frame: CGRect(x: 20, y: 40, width: 200, height: 60))
    let tataAIG_base_url = "https://uathealthvas.tataaig.com"
    let tataAIG_auth_token = "Basic Z2V0X3Zpc2l0OkZoNjh2JHdqaHU4WWd3NiQ="
    let uatLastSyncTime = "1649742210000"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // show button programattically, in actual app this can be ignored
        self.showButton()
        
        // include this line to include video calling
        visitHealthView.videoCallDelegate = self;
        
        // passing tataAIG_base_url and tataAIG_auth_token in form of a dictionary
        visitHealthView.initialParams(["tataAIG_base_url":tataAIG_base_url, "tataAIG_auth_token":tataAIG_auth_token,"uatLastSyncTime":uatLastSyncTime])
        visitHealthView.callHraApi()
        
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
        
        
        self.view.addSubview(button2)
        button2.center = CGPoint(x: view.frame.size.width  / 2, y: view.frame.size.height / 3)
        button2.setTitle("Call HRA API", for: .normal)
        button2.backgroundColor = .blue
        button2.setTitleColor(UIColor.white, for: .normal)
        button2.addTarget(self, action: #selector(self.hraButtonTapped), for: .touchUpInside)
    }
    
    @objc func hideButton(){
        button.removeFromSuperview()
    }
    
    @objc func hideButton2(){
        button2.removeFromSuperview()
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
            case "StartVideoCall":
                print("start video call")
            case "HRAQuestionAnswered":
                print("HRAQuestionAnswered,",current,"of",total)
//            case "hraInComplete":
                
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
        self.hideButton2()
        // adding subview and loading url, below statements need to be called in same order
        visitHealthView.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(visitHealthView.view)
        visitHealthView.loadVisitWebUrl("https://tata-aig.getvisitapp.xyz/sso?userParams=_FrVgrpADBIjcWqmVhp8qikkfp2z_J-Nak09HEqnweQGZv6uyPozfjlJEHmadAeTYkQF87ih_ld8zvEigDA6rHhVQaATBznnAeFy1wGITSbPbKTFaodW8MUlgI6Hk8xNkcGXc-E0S1V5OCxkrmiSn7WVt4jcoVr-G_eaOAPgVIjhGJCcyy438u5hH-Swo3Gq&clientId=tata-aig-a8b455",caller: self)
    }
    
    @objc func hraButtonTapped(sender : UIButton) {
        visitHealthView.callHraApi()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

