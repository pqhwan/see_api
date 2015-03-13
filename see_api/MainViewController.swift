//
//  ViewController.swift
//  see_api
//
//  Created by Pete Kim on 3/12/15.
//  Copyright (c) 2015 Pete Kim. All rights reserved.
//

import UIKit
import Parse

class MainViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var testObject: PFObject = PFObject(className: "test")
        testObject["foo"] = "bar"
        testObject.saveInBackground()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

