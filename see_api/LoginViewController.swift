//
//  LoginViewController.swift
//  see_api
//
//  Created by Pete Kim on 3/15/15.
//  Copyright (c) 2015 Pete Kim. All rights reserved.
//

import Foundation
import UIKit
import Parse

class LoginViewController: UIViewController, UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var pwField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var profilePictureButton: UIButton!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    
    @IBAction func dismissSelf(sender: UIBarButtonItem) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func logoutButtonClicked(sender: UIButton!) {
        var myRelation = PFRelation()
        
        
        if PFUser.currentUser() == nil {
            notifyError("can't log out -- no user present", self, nil)
        } else {
            PFUser.logOut()
            self.statusLabel.text = "no user logged in"
        }
    }
    
    @IBAction func signupButtonClicked(sender: UIButton!) {
        let username = self.usernameField.text
        let password = self.pwField.text
        
        if username.isEmpty || password.isEmpty {
            notifyError("pw or username missing", self, nil)
            return
        }
        
        if let p = self.profileImage {
            var user = PFUser()
            user.username = username
            user.password = password
            
            let imageData = UIImagePNGRepresentation(p)
            let imageFile = PFFile(name:"image.png", data:imageData)
            user["profilePicture"] = imageFile
            
            user.signUpInBackgroundWithBlock({
                (success: Bool!, error: NSError!) -> Void in
                if success == true {
                    self.statusLabel.text = "user logged in: \(PFUser.currentUser().username)"
                }
                
                
            })
            
        } else {
            notifyError("no profile image selected", self, nil)
            return
        }
        
    }
    @IBAction func loginButtonClicked(sender: UIButton!){
        let username = self.usernameField.text
        let password = self.pwField.text
        
        PFUser.logInWithUsernameInBackground(username, password: password, block: {
            (user: PFUser!, error: NSError!) -> Void in
            if error == nil{
                self.statusLabel.text = "user logged in: \(PFUser.currentUser().username)"
            }
            
            if user == nil {
                notifyError("login failed", self, nil)
                return
            }
            
            let imageFile: PFFile = user["profilePicture"] as PFFile
            imageFile.getDataInBackgroundWithBlock({
                (imageData: NSData!, error: NSError!) in
                
                if error != nil {
                    println("error!")
                    println(error.userInfo?["error"])
                    return
                }
                var thisImage: UIImage! = UIImage(data: imageData)
                self.profilePictureButton.setBackgroundImage(thisImage, forState: .Normal)
            })
        })
        
    }
    
    @IBAction func profilePictureButtonClicked(sender: UIButton){
        self.showActionSheetForUpload()
    }
    
   
    var imagePicker: UIImagePickerController?
    var profileImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        if PFUser.currentUser() == nil {
            self.statusLabel.text = "no user logged in"
        } else {
            self.statusLabel.text = "user logged in:\(PFUser.currentUser().username)"
            
            let imageFile: PFFile = PFUser.currentUser()["profilePicture"] as PFFile
            imageFile.getDataInBackgroundWithBlock({
                (imageData: NSData!, error: NSError!) in
                
                if error != nil {
                    println("error!")
                    println(error.userInfo?["error"])
                    return
                }
                var thisImage: UIImage! = UIImage(data: imageData)
                self.profilePictureButton.setBackgroundImage(thisImage, forState: .Normal)
            })
        }
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        let title: String! = actionSheet.buttonTitleAtIndex(buttonIndex)
        if title == "cancel" {
            return
        }
        
        // pick source type
        var sourceType: UIImagePickerControllerSourceType?
        if title == "camera" && UIImagePickerController.isSourceTypeAvailable(.Camera){
            sourceType = .Camera
        }
        if title == "existing" && UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary){
            sourceType = .PhotoLibrary
        }
        
        // start a image picker routine or error
        if let s = sourceType {
            // sourcetype found
            imagePicker = UIImagePickerController()
            imagePicker!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker!.delegate = self
            self.presentViewController(imagePicker!, animated: true, completion: nil)
        } else {
            notifyError("Chosen method is not available", self, {
                (alertAction) in
                self.showActionSheetForUpload()
            })
        }
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.profilePictureButton.setBackgroundImage(image, forState: .Normal)
        self.profileImage = image
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showActionSheetForUpload(){
        let actionSheet = UIActionSheet(title: "Choose uploading method", delegate: self, cancelButtonTitle: "cancel", destructiveButtonTitle: nil)
        actionSheet.addButtonWithTitle("camera")
        actionSheet.addButtonWithTitle("existing")
        actionSheet.showInView(self.view)
    }
    
}
