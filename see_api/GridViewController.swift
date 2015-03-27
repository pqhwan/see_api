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
  
  class PhotoObject {
    var parseObject: PFObject!
    var image: UIImage!
    let index: Int!
    
    init(parseObject: PFObject!, image: UIImage!, index: Int!){
      self.parseObject = parseObject
      self.image = image
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
      println("local gallery query called")
      return self.getLocalLatestCompetitionIfLocalGalleryFound(task)
    }).continueWithBlock({
      (task: BFTask!) -> AnyObject! in
      println("local latest competition query called")
      return self.setLocalLatestCompetitionIfLocalLatestCompetitionFound(task)
    }).continueWithBlock({
      (task: BFTask!) -> AnyObject! in
      println("local latest competition set")
      return self.getLocalSubmissionsIfLocalLatestCompetitionSet(task)
    }).continueWithBlock({
      (task: BFTask!) -> AnyObject! in
      println("local submissions query called")
      
      // this is where we load locally stored submissions
      let localSubmissions = task.result as [PFObject]!
      for var index = 0; index < localSubmissions.count; index++ {
        let localSubmission = localSubmissions[index]
        let photoObject = PhotoObject(parseObject: localSubmission, image: nil, index: index)
        self.photos.append(photoObject)
        
        // retrieve photos for these from disk and, in callback, set to photoObject.image and reloadData
       

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
      }
      
      // call maintainSubmissionList
      // will make async requests for image data and will add them to self.photos when done
      // return self.displayLocalSubmissionsAndUpdateSubmissionsListIfLocalSubmissionsFound(task)
    }).continueWithBlock({
      (task: BFTask!) -> AnyObject! in
      // locally stored submissions have been dug up and their images have been requested for
      return self.updateSubmissionList()
    }).continueWithBlock({
      (task: BFTask!) -> AnyObject! in
      
      if task.error != nil {
        println("error found on gridview update")
        println(task.error)
      }
      
      return nil
    })
  }
  
  // asynchronously update submissions for this competition
  func updateSubmissionList() -> BFTask! {
    let taskSource = BFTaskCompletionSource()
    
    let submissionQuery = PFQuery(className: "Submission")
    submissionQuery.whereKey("competitionId", equalTo: self.competition["competitionId"])
    submissionQuery.addDescendingOrder("createdAt")
   
    // find the latest submission on disk
    // TODO we can replace this by loading local copies first and then chaining this call to it so that
    // this information is available on self.photos
    let latestDownloadedSubmisionQuery = PFQuery(className: "Submission_local").fromLocalDatastore()
    latestDownloadedSubmisionQuery.whereKey("competitionId", equalTo: self.competition["competitionId"])
    latestDownloadedSubmisionQuery.addDescendingOrder("submissionCreatedAt")
    latestDownloadedSubmisionQuery.getFirstObjectInBackground().continueWithBlock({
      (task: BFTask!) -> AnyObject! in
      
      let latestDownloadedSubmission = task.result as PFObject!
      if latestDownloadedSubmission != nil {
        submissionQuery.whereKey("createdAt", greaterThan: (latestDownloadedSubmission["submissionCreatedAt"] as NSDate))
      }
      
      // get me everything more recent than this
      return submissionQuery.findObjectsInBackground()
    }).continueWithSuccessBlock({
      (task: BFTask!) -> AnyObject! in
     
      // got new submissions -- gotta display them and store them on disk for next time
      let submissions = task.result as [PFObject]!
      
      for var index = 0; index < submissions.count ; index++ {
        let submission = submissions[index]
        // create local copies of submissions
        let localSubmission = PFObject(className: "Submission_local")
        localSubmission["submissionId"] = submission.objectId
        localSubmission["submissionCreatedAt"] = submission.createdAt
        localSubmission["competitionId"] = submission["competitionId"] as String!
        localSubmission["userId"] = PFUser.currentUser().objectId
        localSubmission["description"] = submission["description"] as String!
        
        // TODO we need to take into account how many submissions we have downloaded already
        let photoObject = PhotoObject(parseObject: localSubmission, image: nil, index: index)
        self.photos.append(photoObject)
        
        // retreive image file with callback
        let imageFile = submission["image"] as PFFile!
        imageFile.getDataInBackground().continueWithSuccessBlock({
          (task: BFTask!) -> AnyObject! in
          println("image found")
          // data now available
          let imageData = task.result as NSData!
          let image = UIImage(data: imageData)!
          photoObject.image = image
          dispatch_async(dispatch_get_main_queue(), {
            () -> Void in
            
            println("index for this object is \(index)")
            //self.collectionView.reloadItemsAtIndexPaths(<#indexPaths: [AnyObject]#>)
            self.collectionView.reloadData()
          })
          // also, store image data on disk (with subsequent callback)
          return nil
        })
      }
      
      //return PFObject.pinAllInBackground(nil)
      taskSource.setResult(nil)
      return BFTask(result: nil)
    }).continueWithSuccessBlock({
      (task: BFTask!) -> AnyObject! in
      
      return nil
    })
    
    return BFTask(result: nil)
  }
  
  func prepareForNewCompetitionAsync(newCompetition: String!) -> BFTask! {
    // empty photo cache & store new competition_local (return competition_local task)
    // these can be parallel
    let taskSource = BFTaskCompletionSource()
    println("prepareForNewCompetitionAsync here")
    
    // if there is a previous competition and it's being maintained
    // IMPORTANT: this will launch a separate "thread" of work that just finds submissions and deletes them
    if self.competition != nil && self.competition["maintained"] as Bool == true {
      // find all Submission objects under oldCompetition
      println("there's a previous competition to be deleted")
      let query = PFQuery(className: "Submission_local")
      query.whereKey("competitionId", equalTo: self.competition["competitionId"] as String)
      query.findObjectsInBackground().continueWithSuccessBlock({
        (task: BFTask!) -> AnyObject! in
        let submissions = task.result as [PFObject]!
        // go through one by one, find the image file and asynchronously request deleting them
        for submission in submissions {
          // TODO code for requesting asynchronous deletion of an image named after submissionId
        }
        // finally, unpin all
        return PFObject.unpinAllInBackground(submissions)
      }).continueWithBlock({
        (task: BFTask!) -> AnyObject! in
        // handle errors
        return nil
      })
    }
    
    // store the new competition object in local datastore
    let competitionQuery = PFQuery(className: "Competition")
    competitionQuery.getObjectInBackgroundWithId(newCompetition).continueWithSuccessBlock({
      (task: BFTask!) -> AnyObject! in
      println("copy of new competition acquired from server")
      let result = task.result as PFObject!
      
      let newCompetition = PFObject(className:"Competition_local")
      newCompetition["competitionId"] = result.objectId
      newCompetition["galleryId"] = result["gallery"] as String
      newCompetition["active"] = result["active"] as Bool
      newCompetition["endDate"] = result["endDate"] as NSDate
      newCompetition["maintained"] = false
      
      return newCompetition.pinInBackground()
    }).continueWithBlock({
      (task: BFTask!) -> AnyObject! in
      // handle errors
      if task.error != nil {
        taskSource.setError(NSError(domain: "failed to store the new competition", code: -1, userInfo: nil))
      } else {
        println("new competition successfully stored")
        taskSource.setResult(task.result)
      }
      return nil
    })
    return taskSource.task
  }
 
 
  /* UPDATE CHAIN FUNCTIONS */
  
  func getLocalLatestCompetitionIfLocalGalleryFound(task: BFTask!) -> BFTask! {
    if task.error != nil{
      return task
    }
    
    let localGallery = task.result as PFObject!
    if localGallery == nil {
      return BFTask(error: NSError(domain: "no local copy of gallery found", code: -1, userInfo: nil))
    }
    let latestCompetitionId = localGallery["latestCompetition"] as String!
    if latestCompetitionId == nil {
      return BFTask(error: NSError(domain: "local copy of gallery has no competition", code: -1, userInfo: nil))
    }
    println("local gallery found")
    
    self.gallery = localGallery
    
    let galleryId = localGallery["galleryId"] as String!
    let localLatestCompetitionQuery = PFQuery(className: "Competition_local").fromLocalDatastore()
    localLatestCompetitionQuery.whereKey("galleryId", equalTo: galleryId)
    localLatestCompetitionQuery.addDescendingOrder("endDate")
    return localLatestCompetitionQuery.getFirstObjectInBackground()
  }
  
  func setLocalLatestCompetitionIfLocalLatestCompetitionFound(task: BFTask! ) -> BFTask! {
    if task.error != nil {
      return task
    }
    
    let localLatestCompetition = task.result as PFObject!
    if localLatestCompetition == nil {
      println("no local competition stored")
    } else {
      println("local copy of competition found")
    }
    self.competition = localLatestCompetition
    
    let remoteLatestCompetitionId = self.gallery["latestCompetition"] as String!
    if localLatestCompetition == nil || localLatestCompetition["competitionId"] as String! != remoteLatestCompetitionId{
      println("there's new competition to be downloaded -- calling prepareForNewCompetitionAsync")
      return self.prepareForNewCompetitionAsync(remoteLatestCompetitionId)
    } else {
      println("local latest competition is actually the latest")
      return BFTask(result: localLatestCompetition)
    }
  }
  
  func getLocalSubmissionsIfLocalLatestCompetitionSet(task: BFTask!) -> BFTask! {
    if task.error != nil {
      return task
    }
    
    self.competition = task.result as PFObject!
    // retrieve submissions stored in local data store
    let localSubmissionsQuery = PFQuery(className: "Submission_local").fromLocalDatastore()
    localSubmissionsQuery.whereKey("competitionId", greaterThan: self.competition["competitionId"])
    localSubmissionsQuery.addDescendingOrder("submissionCreatedAt")
    return localSubmissionsQuery.findObjectsInBackground()
  }
  
  func displayLocalSubmissionsAndUpdateSubmissionsListIfLocalSubmissionsFound(task: BFTask!) -> BFTask! {
    return nil
  }
 
  
  
  /* COLLECTION VIEW DELEGATE & DATASOURCE PROTOCOL FUNCTIONS */
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    println("collectionView numberOfItemsInSection called")
    return photos.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    println("collectionView cellForItemAtIndexPath called")
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as photoCell
    let photoObject = self.photos[indexPath.row]
    cell.imageView.image = photoObject.image
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    
  }
}