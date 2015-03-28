//
//  GridViewController.swift
//  see_api
//
//  Created by Pete Kim on 3/14/15.
//  Copyright (c) 2015 Pete Kim. All rights reserved.
//

import UIKit
import Parse
import Bolts

class GridViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let reuseIdentifier = "photoCell"
    var photos = [PhotoObject]()
    var competition: PFObject! = nil
    var gallery: PFObject! = nil
    var dirPath: String!
    
    class PhotoObject {
        var parseObject: PFObject!
        var image: UIImage!
        let index: Int!
        
        init(parseObject: PFObject!, image: UIImage!, index: Int!){
            self.parseObject = parseObject
            self.image = image
            self.index = index
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = false
        // assume this was given
        let galleryName = "providence_0"
        // chain 0 -- get locally stored gallery, make sure it is good, and use it to get latest local competition
        let localGalleryQuery = PFQuery(className:"Gallery_local").fromLocalDatastore()
        localGalleryQuery.whereKey("name", equalTo: galleryName)
        localGalleryQuery.getFirstObjectInBackground().continueWithBlock({
            (task: BFTask!) -> AnyObject! in
            return self.getLocalLatestCompetitionIfLocalGalleryFound(task)
        }).continueWithBlock({
            (task: BFTask!) -> AnyObject! in
            return self.setLocalLatestCompetitionIfLocalLatestCompetitionFound(task)
        }).continueWithBlock({
            (task: BFTask!) -> AnyObject! in
            return self.getLocalSubmissionsIfLocalLatestCompetitionSet(task)
        }).continueWithBlock({
            (task: BFTask!) -> AnyObject! in
            return self.displayLocalSubmissionsIfLocalSubmissionsFound(task)
        }).continueWithBlock({
            (task: BFTask!) -> AnyObject! in
            return self.updateLocalSubmissions(task)
        }).continueWithBlock({
            (task: BFTask!) -> AnyObject! in
            println("updates done!")
            return nil
        })
    }
    
   
    // ADD NEW COMPETITION & DELETE PREVIOUS CACHE IF NECESSARY
    func prepareForNewCompetitionAsync(newCompetition: String!) -> BFTask! {
        println("prepare for new competition (id: \(newCompetition))")
        let taskSource = BFTaskCompletionSource()
        
        // IF THERE'S CACHE TO BE DELETED FROM PREVIOUS COMPETITION
        if self.competition != nil && self.competition["maintained"] as Bool == true {
            println("there's cache to be deleted from previous competition")
            // PREPARE QUERY TO FIND SUBMISSIONS FROM PREVIOUS COMPETITION
            let query = PFQuery(className: "Submission_local")
            query.whereKey("competitionId", equalTo: self.competition["competitionId"] as String)
            
            // FIND SUBMISSIONS FROM PREVIOUS COMPETITION
            query.findObjectsInBackground().continueWithBlock({
                (task: BFTask!) -> AnyObject! in
                // DELETE PHOTOS IN FILE SYSTEM
                let submissions = task.result as [PFObject]!
                let competitionId = self.competition["competitionId"] as String!
                return self.deletePhotosUnderCompetition(competitionId, submissions: submissions)
            }).continueWithBlock({
                (task: BFTask!) -> AnyObject! in
                // UNPIN OBJECTS
                let submissions = task.result as [PFObject]!
                return PFObject.unpinAllInBackground(submissions)
            }).continueWithBlock({
                (task: BFTask!) -> AnyObject! in
                return nil
            })
        } else {
            println("no cache to be deleted")
        }
        
        // GET THE NEW COMPETITION OBJECT FROM SERVER
        let competitionQuery = PFQuery(className: "Competition")
        competitionQuery.getObjectInBackgroundWithId(newCompetition).continueWithSuccessBlock({
            (task: BFTask!) -> AnyObject! in
            println("got competition object")
            
            // SAVE THE LOCAL VERISON OF THE NEW COMPETITION
            let result = task.result as PFObject!
            let newLocalCompetition = PFObject(className:"Competition_local")
            newLocalCompetition["competitionId"] = result.objectId
            newLocalCompetition["galleryId"] = result["gallery"] as String
            newLocalCompetition["active"] = result["active"] as Bool
            newLocalCompetition["endDate"] = result["endDate"] as NSDate
            newLocalCompetition["maintained"] = false
            newLocalCompetition.pinInBackgroundWithBlock({
                (success: Bool, error: NSError!) in
                taskSource.setResult(newLocalCompetition)
            })
            return nil
        })
            
        return taskSource.task
    }
   
    // DELETE PHOTOS UNDER SELF.COMPETIITON
    func deletePhotosUnderCompetition(id: String!, submissions: [PFObject]!) -> BFTask{
        let taskSource = BFTaskCompletionSource()
        var path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let dirPath = path.stringByAppendingPathComponent("images/\(id)")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            let manager = NSFileManager.defaultManager()
            for submission in submissions {
                let submissionId = submission["submissionId"] as String!
                let imagePath = dirPath.stringByAppendingPathComponent("/\(submissionId)")
                
                if( manager.isDeletableFileAtPath(imagePath) ) {
                    manager.removeItemAtPath(imagePath, error: nil)
                } else {
                    println("imageFile at \(imagePath) couldn't be deleted")
                }
            }
            taskSource.setResult(nil)
        })
        return taskSource.task
    }
    
    /* UPDATE CHAIN FUNCTIONS */
   
    // GIVEN THAT A LOCAL COPY OF GALLERY HAS BEEN FOUND, QUERY FOR LOCAL COPY OF LATEST COMPETITION
    func getLocalLatestCompetitionIfLocalGalleryFound(task: BFTask!) -> BFTask! {
        println("get local latste competition if local gallery is found")
        self.gallery = task.result as PFObject!
        
        // QUERY FOR LOCAL COPY OF LATEST COMPETITION
        let galleryId = self.gallery["galleryId"] as String!
        let localLatestCompetitionQuery = PFQuery(className: "Competition_local").fromLocalDatastore()
        localLatestCompetitionQuery.whereKey("galleryId", equalTo: galleryId)
        localLatestCompetitionQuery.addDescendingOrder("endDate")
        return localLatestCompetitionQuery.getFirstObjectInBackground()
    }
   
    // GIVEN THAT LOCAL COPY OF LATEST COMPETITION HAS BEEN FOUND, CHECK IF IT IS IN FACT THE LATEST
    func setLocalLatestCompetitionIfLocalLatestCompetitionFound(task: BFTask! ) -> BFTask! {
        println("set local latest competition if local latest competition is found")
        self.competition = task.result as PFObject!
       
        // SET COMPETITION STRIAGHT
        let remoteLatestCompetitionId = self.gallery["latestCompetition"] as String!
        if self.competition == nil || self.competition["competitionId"] as String! != remoteLatestCompetitionId{
            println("there's new competition to be downloaded -- calling prepareForNewCompetitionAsync")
            return self.prepareForNewCompetitionAsync(remoteLatestCompetitionId)
        } else {
            println("local latest competition is actually the latest")
            return BFTask(result: self.competition)
        }
    }
   
    // GIVEN THAT LATEST COMPETITION HAS BEEN FOUND AND SET, GET LOCAL SUBMISSIONS UNDER THE COMPETITION
    func getLocalSubmissionsIfLocalLatestCompetitionSet(task: BFTask!) -> BFTask! {
        println("get local submissions if local latest competition is set")
        self.competition = task.result as PFObject!
        
        // CREATE DIRECTORY TO STORE IMAGE FILES IN
        let competitionId = competition["competitionId"] as String!
        var path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        self.dirPath = path.stringByAppendingPathComponent("images/\(competitionId)")
        let manager = NSFileManager.defaultManager()
        if manager.fileExistsAtPath(self.dirPath) == false {
            manager.createDirectoryAtPath(self.dirPath, withIntermediateDirectories: true, attributes: nil, error: nil)
        }
        println("directory for this competition's images is \(self.dirPath)")
        
        // RETREIVE LOCALLY STORED SUBMISSIONS
        let localSubmissionsQuery = PFQuery(className: "Submission_local").fromLocalDatastore()
        localSubmissionsQuery.whereKey("competitionId", equalTo: self.competition["competitionId"])
        localSubmissionsQuery.addDescendingOrder("submissionCreatedAt")
        return localSubmissionsQuery.findObjectsInBackground()
    }
    
    // GIVEN THAT LOCAL SUBMISSIONS WERE RETRIEVED, DISPLAY THEM
    func displayLocalSubmissionsIfLocalSubmissionsFound(task: BFTask) -> BFTask{
        let localSubmissions = task.result as [PFObject]!
        
        println("display local submissions if local submissions are found")
        println("number of submissions in local datastore :\(localSubmissions.count)")
        
        for var index = 0; index < localSubmissions.count; index++ {
            // PUT THEM IN PHOTOS
            println("iteration \(index)")
            let localSubmission = localSubmissions[index]
            let photoObject = PhotoObject(parseObject: localSubmission, image: nil, index: index)
            self.photos.append(photoObject)
            dispatch_async(dispatch_get_main_queue(), {
                self.collectionView.reloadData()
            })
            
            // REQUEST FOR IMAGES FROM FILE SYSTEM
            let submissionId = localSubmission["submissionId"] as String!
            let imagePath = self.dirPath.stringByAppendingPathComponent("/\(submissionId).png")
            self.retrieveImageLocallyAndDisplay(imagePath, atRow: index)
        }
        return BFTask(result: nil)
    }
    
    func retrieveImageLocallyAndDisplay(imagePath: String!, atRow: Int!){
        // SET IMAGES TO PHOTOS
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            let image = UIImage(contentsOfFile: imagePath)
            println("photo found for \(atRow)")
            self.photos[atRow].image = image
            let indexPath = NSIndexPath(forRow: atRow, inSection: 0)
            
            // CALL RELOAD ON CORRESPONDING CELLS
            dispatch_async(dispatch_get_main_queue(), {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            })
        })
    }
    
    
    // RETRIEVE NEW SUBMISSIONS FROM SERVER AND DISPLAY THEM
    func updateLocalSubmissions(task: BFTask) -> BFTask! {
        println("update local submissions")
        let taskSource = BFTaskCompletionSource()
        
        // PREPARE QUERY TO RETRIEVE NEW SUBMISSIONS
        let submissionQuery = PFQuery(className: "Submission")
        submissionQuery.whereKey("competitionId", equalTo: self.competition["competitionId"])
        submissionQuery.addDescendingOrder("createdAt")
        if self.photos.count > 0 {
            println("self photos count \(self.photos.count)")
            let latestDownloadedSubmission = self.photos[0].parseObject
            submissionQuery.whereKey("createdAt", greaterThan: (latestDownloadedSubmission["submissionCreatedAt"] as NSDate))
        }
        
        // QUERY FOR NEW SUBMISSIONS
        submissionQuery.findObjectsInBackground().continueWithSuccessBlock({
            (task: BFTask!) -> AnyObject! in
            println("new submissions retrieved")
            let submissions = task.result as [PFObject]!
            println("number of new submissions retrieved from server: \(submissions.count)")
            let baseIndex = self.photos.count
            
            var newLocalSubmissions = [PFObject]()
            
            // FOR EACH NEW SUBMISSION OBJECT
            for var index = 0; index < submissions.count ; index++ {
                let submission = submissions[index]
                
                // CREATE LOCAL COPY AND PUT IT IN PHOTOS
                let localSubmission = PFObject(className: "Submission_local")
                localSubmission["submissionId"] = submission.objectId
                localSubmission["submissionCreatedAt"] = submission.createdAt
                localSubmission["competitionId"] = submission["competitionId"] as String!
                localSubmission["userId"] = PFUser.currentUser().objectId
                localSubmission["description"] = submission["description"] as String!
                newLocalSubmissions.append(localSubmission)
                let photoObject = PhotoObject(parseObject: localSubmission, image: nil, index: (baseIndex+index))
                self.photos.append(photoObject)
                dispatch_async(dispatch_get_main_queue(), {
                    self.collectionView.reloadData()
                })
                
                // REQUEST IMAGE FILE FROM SERVER
                let imageFile = submission["image"] as PFFile!
                imageFile.getDataInBackground().continueWithSuccessBlock({
                    (task: BFTask!) -> AnyObject! in
                    
                    // CREATE UIIMAGE, PUT IT UNDER PHOTOS AND RELOAD
                    let imageData = task.result as NSData!
                    let image = UIImage(data: imageData)!
                    photoObject.image = image
                    let indexPath = NSIndexPath(forRow: photoObject.index, inSection: 0)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.collectionView.reloadItemsAtIndexPaths([indexPath])
                    })
                    
                    // REQUEST IMAGE TO BE STORED ON DISK
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                        let imagePath = self.dirPath.stringByAppendingPathComponent("/\(submission.objectId).png")
                        imageData.writeToFile(imagePath, atomically: true)
                    })
                    return nil
                })
            }
            self.competition["maintained"] = true
            return PFObject.pinAllInBackground(newLocalSubmissions)
        }).continueWithSuccessBlock({
            (task: BFTask!) -> AnyObject! in
            taskSource.setResult(nil)
            return nil
        })
        
        return BFTask(result: nil)
    }
    
    
    /* COLLECTION VIEW DELEGATE & DATASOURCE PROTOCOL FUNCTIONS */
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as photoCell
        let photoObject = self.photos[indexPath.row]
        cell.imageView.image = photoObject.image
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
}