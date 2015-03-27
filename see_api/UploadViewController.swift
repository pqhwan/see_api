//
//  UploadViewController.swift
//  see_api
//
//  Created by Pete Kim on 3/14/15.
//  Copyright (c) 2015 Pete Kim. All rights reserved.
//

import Parse
import UIKit

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate ,UIActionSheetDelegate, UITextViewDelegate {
    
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
   
    var controller: UIImagePickerController?
    
    // action sheet titles
    let newPhotoTitle: String! = "Take New Photo"
    let existingPhotoTitle: String! = "Choose from Existing"
    let cancelTitle: String! = "Cancel"
    
    // defaults
    let textViewDefaultPrompt: String! = "Write a few words..."
    let imageViewDefault: UIImage! = UIImage(named: "uploadPrompt")
    let competitionId = "zmA2eALt2c"
   
    @IBAction func uploadButtonClicked(sender: UIButton!){
        // TODO check for correct input
        if imageView.image == self.imageViewDefault {
            notifyError("No image uploaded", self, nil)
            return
        }
        
        if textView.text == self.textViewDefaultPrompt {
            notifyError("No text written", self, nil)
            return
        }
   
        let imageData = UIImagePNGRepresentation(imageView.image)
        let imageFile = PFFile(name:"image.png", data:imageData)
        
        var userPhoto = PFObject(className: "Submission")
        userPhoto["image"] = imageFile
        userPhoto["description"] = textView.text
        userPhoto["userId"] = PFUser.currentUser().objectId
        userPhoto["competitionId"] = self.competitionId
        
        userPhoto.saveInBackgroundWithBlock({
            (success: Bool!, error: NSError!) in
            if error != nil {
                println( (error.userInfo?["error"] as NSString) )
            } else {
                println("saved! check data browser")
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.navigationController?.navigationBarHidden = false
        
        self.textView.text = self.textViewDefaultPrompt
        self.imageView.image = imageViewDefault
        
        // configure imageView to work as an upload button
        self.imageView.userInteractionEnabled = true
        self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showActionSheetForUpload"))
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if self.textView.text == self.textViewDefaultPrompt{
            self.textView.text = ""
        }
        return true
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        } else {
            return true
        }
    }
    
    
    func showActionSheetForUpload(){
        let actionSheet = UIActionSheet(title: "Choose uploading method", delegate: self, cancelButtonTitle: self.cancelTitle, destructiveButtonTitle: nil)
        actionSheet.addButtonWithTitle(self.newPhotoTitle)
        actionSheet.addButtonWithTitle(self.existingPhotoTitle)
        actionSheet.showInView(self.view)
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        let title: String! = actionSheet.buttonTitleAtIndex(buttonIndex)
        if title == self.cancelTitle {
            return
        }
       
        // pick source type
        var sourceType: UIImagePickerControllerSourceType?
        if title == self.newPhotoTitle && UIImagePickerController.isSourceTypeAvailable(.Camera){
            sourceType = .Camera
        }
        if title == self.existingPhotoTitle && UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary){
            sourceType = .PhotoLibrary
        }
  
        // start a image picker routine or error
        if let s = sourceType {
            // sourcetype found
            controller = UIImagePickerController()
            controller!.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            controller!.delegate = self
            self.presentViewController(controller!, animated: true, completion: nil)
        } else {
            notifyError("Chosen method is not available", self, {
                (alertAction) in
                self.showActionSheetForUpload()
            })
        }
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.imageView.image = image
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
   
    /*
    func keyboardFrameDidChange(notification: NSNotification){
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
        UIView.animateWithDuration(1.0, animations: {
            let keyboardHeight = keyboardFrame.size.height
            
            self.uploadButton.frame = self.makeCGRectToMoveView(self.uploadButton, vertically: keyboardHeight)
            self.imageView.frame = self.makeCGRectToMoveView(self.imageView, vertically: keyboardHeight)
            self.textView.frame = self.makeCGRectToMoveView(self.textView, vertically: keyboardHeight)
        })
        
        UIView.animateWithDuration(1.0, animations: {
            
        })
    }
    
    func makeCGRectToMoveView(target: UIView!, vertically: CGFloat!) -> CGRect{
        let viewX = self.uploadButton.frame.origin.x
        let viewY = self.uploadButton.frame.origin.y
        let viewHeight = self.uploadButton.frame.size.height
        let viewWidth = self.uploadButton.frame.size.width
        
        return CGRectMake(viewX, viewY - vertically, viewWidth, viewHeight)
    }
    */

    
}



