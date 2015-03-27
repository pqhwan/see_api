//
//  LikeViewController.swift
//  see_api
//
//  Created by Pete Kim on 3/17/15.
//  Copyright (c) 2015 Pete Kim. All rights reserved.
//

import Foundation
import UIKit
import Parse


// implement:
// liking a photo: adding likes to the user's relation "likes"
// unliking a photo: s
// getting all photos user has liked
//


class LikeViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var test = PFObject(className: "testObject")
        test["active"] = true
        
        if test.pin() == false {
            println("fail")
        } else {
            println("success")
        }
        
        
        var query = PFQuery(className: "testObject")
        query.fromLocalDatastore()
        
        query.findObjectsInBackgroundWithBlock({
            (objects: [AnyObject]!, err: NSError!) in
            println("query ran")
            
            if err != nil {
                println("ther was an error")
                return
            }
            
            if objects.count == 0 {
                println("object not found")
                return
            }
            
            if let o = objects as? [PFObject] {
                for object in o {
                    let active = object["active"] as Bool!
                    println("\(active)")
                }
            }
            
            
            
        })
        
    }
    
    
    
}