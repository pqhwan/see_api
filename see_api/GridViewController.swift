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
  var photos = [UIImage]()
  var competition: PFObject! = nil
  var gallery: PFObject! = nil
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBarHidden = false
    
    // assume this was given
    let galleryName = "providence_0"
   
    // chain 0 -- get locally stored gallery, make sure it is good, and use it to get latest local competition
    let localGalleryQuery = PFQuery(className:"Gallery_local").fromLocalDatastore()
    localGalleryQuery.whereKey("name", equalTo: galleryName)
    localGalleryQuery.getFirstObjectInBackground().continueWithSuccessBlock({
      (task: BFTask!) -> AnyObject! in
     
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
    }).continueWithBlock({
      (task: BFTask!) -> AnyObject! in
     
      let localLatestCompetition = task.result as PFObject!
      if localLatestCompetition == nil {
        println("no local competition stored")
      }
      
      self.competition = localLatestCompetition
      
      //let localLatestCompetitionId = localLatestCompetition["competitionId"] as String!
      let remoteLatestCompetitionId = self.gallery["latestCompetition"] as String!
      
      if localLatestCompetition == nil || localLatestCompetition["competitionId"] as String! != remoteLatestCompetitionId{
        println("there's new competition to be downloaded -- calling prepareForNewCompetitionAsync")
        return self.prepareForNewCompetitionAsync(remoteLatestCompetitionId)
      } else {
        return BFTask(result: localLatestCompetition)
      }
    }).continueWithSuccessBlock({
      (task: BFTask!) -> AnyObject! in
      self.competition = task.result as PFObject!
      
      if (self.competition["maintained"] as Bool) {
        // update list
        
      } else {
        // initiate list
        // download submissions
        
      }
      
      return BFTask(result: nil)
    }).continueWithBlock({
      (task: BFTask!) -> AnyObject! in
      
      if task.error != nil {
        println(task.error)
      }
      return nil
    })
    
   
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
  
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    //println("number of items requested (currently \(photos.count))")
    return photos.count
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as photoCell
    cell.backgroundColor = UIColor.blackColor()
    cell.imageView.image = self.photos[indexPath.row]
    // Configure the cell
    return cell
  }
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    
  }
}
 
  /*
  func updateCompetitionForGalleryAsync(name: String!) -> BFTask! {
    println("gallery update called for gallery \(name)")
    
    let taskSource = BFTaskCompletionSource()
    
    let localGalleryQuery = PFQuery(className: "Gallery_local")
    localGalleryQuery.whereKey("name", equalTo: name)
    localGalleryQuery.getFirstObjectInBackground().continueWithBlock({
      (task: BFTask!) -> AnyObject! in
      let localGallery = task.result as PFObject!
      if localGallery == nil {
        taskSource.setError(NSError(domain: "no local gallery found", code: -1, userInfo: nil))
        return nil
      }
      self.gallery = localGallery
      
      //local gallery available from here on
      let localLatestCompetitionQuery = PFQuery(className: "Competition_local").fromLocalDatastore()
      localLatestCompetitionQuery.whereKey("galleryId", equalTo: localGallery["galleryId"])
      // FIXME sorting by endDate might not always give the latest competition
      localLatestCompetitionQuery.orderByDescending("endDate")
      
      return localLatestCompetitionQuery.getFirstObjectInBackground().continueWithBlock({
        (task: BFTask!) -> AnyObject! in
        
        let localLatestCompetition = task.result as PFObject!
        if localLatestCompetition == nil {
          // first download of competition
          println("first download of competition")
          // add new competition 
          self.competition = self.addNewCompetitionForGallery(name, competitionId: localGallery["latestCompetition"] as String!)
          return nil
        }
        
        if localLatestCompetition["competitionId"] as String != localGallery["latestCompetition"] as String {
          println("latest local competition is outdated")
          if localLatestCompetition["active"] as Bool {
            println("user missed grace period of previous competition")
            self.competition = self.addNewCompetitionForGallery(name, competitionId: localGallery["latestCompetition"] as String!)
            // TODO delete submission cache
            return nil
          } else {
            println("user has seen grace period of previous competition")
            self.competition = self.addNewCompetitionForGallery(name, competitionId: localGallery["latestCompetition"] as String!)
            // TODO delete grace period cache
            return nil
          }
        }
        return nil
      })
    })
    return taskSource.task
  }*/
  
  
  
 
  /*
  func updateCompetitionForGallery(name: String!){
    println("gallery update called for gallery \(name)")
    
    let localGalleryQuery = PFQuery(className: "Gallery_local").fromLocalDatastore()
    localGalleryQuery.whereKey("name", equalTo: name)
    localGalleryQuery.getFirstObjectInBackground().continueWithBlock({
      (task: BFTask!) -> AnyObject! in
      
      let localGallery = task.result as PFObject!
      self.gallery = localGallery
      
      if localGallery == nil {
        return BFTask(error: NSError(domain: "no local gallery found", code: -1, userInfo: nil))
      }
      
      // local gallery available from here on
      
      let localLatestCompetitionQuery = PFQuery(className: "Competition_local").fromLocalDatastore()
      localLatestCompetitionQuery.whereKey("galleryId",
        equalTo: localGallery["galleryId"])
      // FIXME sorting by endDate might not always give the latest competition
      localLatestCompetitionQuery.orderByDescending("endDate")
      
      // get locally stored latest competition and see if anything has changed, and if not, update photo cache
      // returns BFTask to indicate success or failure
      return localLatestCompetitionQuery.getFirstObjectInBackground().continueWithBlock({
        (task: BFTask!) -> AnyObject! in
        
        let localLatestCompetition = task.result as PFObject!
        self.competition = localLatestCompetition
        
        if localLatestCompetition == nil {
          // first download of competition
          println("first download of competition")
          self.addNewCompetitionForGallery(name, competitionId: localGallery["latestCompetition"] as String!)
          // TODO start submissions cache
          return nil
        }
        
        if localLatestCompetition["competitionId"] as String != localGallery["latestCompetition"] as String {
          // was local one in active state?
          println("latest local competition is outdated")
          if localLatestCompetition["active"] as Bool {
            println("user missed grace period of previous competition")
            // TODO delete submission cache
          } else {
            println("user has seen grace period of previous competition")
            // TODO delete grace period cache
          }
          
          if localGallery["competitionActive"] as Bool {
            // new competition is active -- start a submissiosn cache
            println("new competition is active")
            self.addNewCompetitionForGallery(name, competitionId: localGallery["latestCompetition"] as String!)
            // TODO start submission cache
            return nil
          } else {
            // new competition is inactive -- start a grace period cache
            println("new competition is already in grace period")
            self.addNewCompetitionForGallery(name, competitionId: localGallery["latestCompetition"] as String!)
            // TODO start grace period cache
            return nil
          }
        } else {
          println("latest local competition is in fact the latest")
          // latest competition is the same -- has competition gone into grace period?
          let localStatus = localLatestCompetition["active"] as Bool
          let authStatus = localGallery["competitionActive"] as Bool // authoritative
          
          if localStatus {
            // local is active
            if authStatus {
              println("we're still active -- any updates on list of submissions?")
              // TODO update submission cache
              return nil
            } else {
              println("competition went into grace period")
              // delete submission cache and start grace period cache
              localLatestCompetition["active"] = false
              localLatestCompetition.pinInBackground()
              // TODO delete submission cache
              // TODO start submissions cache
              return nil
            }
          } else {
            // both local and remote copy in grace period
            println("latest compeitition in grace period like last time we checked")
          }
        }
        return nil
      })
    })
  }*/
  
  
  // active cache management
  /*
  
  func initActiveCacheForCompetitionAsync(id: String!) -> BFTask! {
  return nil
  }
  
  func updateActiveCacheForCompetitionAsync(id: String!) -> BFTask! {
  return nil
  }
  
  func deleteActiveCacheForCompetitionAsync(id: String!) -> BFTask! {
  return nil
  }
  
  func initGraceCacheForCompetitionAsync(id: String!) -> BFTask! {
  return nil
  }
  
  func deleteGraceCacheForCompetitionAsync(id: String!) -> BFTask! {
  return nil
  }*/
  
  
  
        /*
        if localLatestCompetition["competitionId"] as String != localGallery["latestCompetition"] as String {
          // was local one in active state?
          println("latest local competition is outdated")
          var resultArr = [AnyObject]()
          if localLatestCompetition["active"] as Bool {
            println("user missed grace period of previous competition")
            // TODO delete submission cache
            resultArr.append(self.DEL_ACTIVE_CACHE)
          } else {
            println("user has seen grace period of previous competition")
            // TODO delete grace period cache
            resultArr.append(self.DEL_GRACE_CACHE)
          }
          
          if localGallery["competitionActive"] as Bool {
            // new competition is active -- start a submissiosn cache
            println("new competition is active")
            self.addNewCompetitionForGallery(name, competitionId: localGallery["latestCompetition"] as String!)
            // start submission cache
            resultArr.append(self.INIT_ACTIVE_CACHE)
          } else {
            // new competition is inactive -- start a grace period cache
            println("new competition is already in grace period")
            self.addNewCompetitionForGallery(name, competitionId: localGallery["latestCompetition"] as String!)
            // TODO start grace period cache
            resultArr.append(self.INIT_GRACE_CACHE)
          }
          taskSource.setResult(resultArr)
          return nil
        } else {
          println("latest local competition is in fact the latest")
          // latest competition is the same -- has competition gone into grace period?
          let localStatus = localLatestCompetition["active"] as Bool
          let authStatus = localGallery["competitionActive"] as Bool // authoritative
          
          if localStatus {
            // local is active
            if authStatus {
              println("we're still active -- any updates on list of submissions?")
              // TODO update submission cache
              taskSource.setResult([self.UPDATE_ACTIVE_CACHE])
              return nil
            } else {
              println("competition went into grace period")
              // delete submission cache and start grace period cache
              localLatestCompetition["active"] = false
              localLatestCompetition.pinInBackground()
              // TODO delete submission cache
              // start submissions cache
              taskSource.setResult([self.INIT_ACTIVE_CACHE])
              return nil
            }
          } else {
            // both local and remote copy in grace period
            println("latest compeitition in grace period like last time we checked")
            taskSource.setResult(nil)
            return nil
          }
        } */
      /*
      if task.error != nil {
        println("\(task.error)")
        return nil
      }
      if task.result == nil {
        println("nothing to do here")
        return nil
      }
      
      var previousTask: BFTask! = nil
      let competitionId = self.competition["competitionId"] as String!
      
      for t in task.result as [Int]! {
        switch t {
        case self.INIT_ACTIVE_CACHE:
          println("init active cache")
          if previousTask == nil {
            previousTask = self.initActiveCacheForCompetitionAsync(competitionId)
          } else {
            previousTask = previousTask.continueWithBlock({
              (task: BFTask!) -> AnyObject! in
              return self.initActiveCacheForCompetitionAsync(competitionId)
            })
          }
        case self.INIT_GRACE_CACHE:
          println("init grace cache")
          if previousTask == nil {
            previousTask = self.initGraceCacheForCompetitionAsync(competitionId)
          } else {
            previousTask = previousTask.continueWithBlock({
              (task: BFTask!) -> AnyObject! in
              return self.initGraceCacheForCompetitionAsync(competitionId)
            })
          }
        case self.UPDATE_ACTIVE_CACHE:
          println("update active cache")
          if previousTask == nil {
            previousTask = self.updateActiveCacheForCompetitionAsync(competitionId)
          } else {
            previousTask = previousTask.continueWithBlock({
              (task: BFTask!) -> AnyObject! in
              return self.updateActiveCacheForCompetitionAsync(competitionId)
            })
          }
        case self.DEL_ACTIVE_CACHE:
          println("delete active cache")
          if previousTask == nil {
            previousTask = self.deleteActiveCacheForCompetitionAsync(competitionId)
          } else {
            previousTask = previousTask.continueWithBlock({
              (task: BFTask!) -> AnyObject! in
              return self.deleteActiveCacheForCompetitionAsync(competitionId)
            })
          }
        case self.DEL_GRACE_CACHE:
          println("delete grace cache")
          if previousTask == nil {
            previousTask = self.deleteGraceCacheForCompetitionAsync(competitionId)
          } else {
            previousTask = previousTask.continueWithBlock({
              (task: BFTask!) -> AnyObject! in
              return self.deleteGraceCacheForCompetitionAsync(competitionId)
            })
          }
        default:
          println("unexpected")
        }
      }
      */
  // state management
  /*
  func addNewCompetitionForGallery(name: String!, competitionId: String!) -> BFTask! {
    let taskSource = BFTaskCompletionSource()
    
    let query = PFQuery(className: "Competition")
    query.getObjectInBackgroundWithId(competitionId).continueWithBlock({
      (task: BFTask!) -> AnyObject! in
      
      let competition = task.result as PFObject!
      
      // TODO error checking (might be revealing point for some serious edge cases near competition transition point)
      if competition == nil {
        // competiiton not found
      }
      
      // check if there's a copy of the same competition
      // this wouldn't happen though
      let countRedundants = PFQuery(className: "Competition_local").fromLocalDatastore()
      countRedundants.whereKey("competitionId", equalTo: competition.objectId)
      if ( countRedundants.countObjects() > 0 ) {
        println("REDUNDANT COPY OF COMPETITION FOUND")
        return nil
      }
      
      let newCompetition = PFObject(className:"Competition_local")
      newCompetition["competitionId"] = competition.objectId
      newCompetition["galleryId"] = competition["gallery"] as String
      newCompetition["active"] = competition["active"] as Bool
      newCompetition["endDate"] = competition["endDate"] as NSDate
      newCompetition["maintained"] = false
      
      newCompetition.pinInBackground().continueWithBlock({
        (task: BFTask!) -> AnyObject! in
        let newCompetition = task.result as PFObject!
        if newCompetition == nil {
          taskSource.setError(NSError(domain: "local save failed", code: -1, userInfo: nil))
        } else {
          taskSource.setResult(nil)
        }
        return nil
      })
      return nil
    })
    
    return taskSource.task
  } */






/*
let batchDownloadQuery = PFQuery(className: "Submissions")
batchDownloadQuery.findObjectsInBackground().continueWithBlock({
(task: BFTask!) -> AnyObject! in
let submissions = task.result as [PFObject]!
var tasks = [BFTask]()

println("\(submissions.count) photos retrieved from the server")

for submission in submissions {
let uploader = submission["user"] as PFUser
let image = submission["image"] as PFFile
let desc = submission["description"] as String

tasks.append(image.getDataInBackground())
}

return nil
}) */