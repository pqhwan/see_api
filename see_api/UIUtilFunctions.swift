//
//  UIUtilFunctions.swift
//  see_api
//
//  Created by Pete Kim on 3/14/15.
//  Copyright (c) 2015 Pete Kim. All rights reserved.
//

import Foundation
import UIKit

public func notifyError(message:String!, controller: UIViewController!, handler: ((UIAlertAction!) -> Void)? ) {
    var alert:UIAlertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
    let cancelAction = UIAlertAction(title: "cancel", style: .Cancel, handler: handler)
    
    alert.addAction(cancelAction)
    controller.presentViewController(alert, animated: true, completion: nil)
}