//
//  ViewController.swift
//  VisitIosHealthSdk
//
//  Created by 81799742 on 01/24/2022.
//  Copyright (c) 2022 81799742. All rights reserved.
//

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
        visitHealthView.loadVisitWebUrl( "https://star-health.getvisitapp.xyz/star-health?token=eyJhbGciOiJIUzI1NiJ9.eyJqdGkiOi[%E2%80%A6]GFsIn0.f0656mzmcRMSCywkbEptdd6JgkDfIqN0S9t-P1aPyt8&id=8158",caller: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

