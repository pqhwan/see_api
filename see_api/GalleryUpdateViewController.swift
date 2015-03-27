//
//  GalleryUpdateViewController.swift
//  see_api
//
//  Created by Pete Kim on 3/25/15.
//  Copyright (c) 2015 Pete Kim. All rights reserved.
//

import UIKit
import Parse
import Bolts


// this is where I test the code that runs every time user opens or reopens an app

class GalleryUpdateViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.navigationController?.navigationBarHidden = false
        
        // based on updated info gallery, compare with local
        // competition object to find out whether competition has ended or a new one has begun
        updateCompetitionForGallery("providence_0");
        
        // check if
        
        // if no latest competition: don't crash and burn but something is not right
        // if latest competition is inactive
        // if latest competition is active
    }
    
    func addNewCompetitionForGallery(name: String!, competitionId: String!){
        let query = PFQuery(className: "Competition")
        query.getObjectInBackgroundWithId(competitionId).continueWithBlock({
            (task: BFTask!) -> AnyObject! in
            
            let competition = task.result as PFObject
            
            // TODO error checking (might be revealing point for some serious edge cases near competition transition point)
            
            // check if there's a copy of the same competition
            // this wouldn't happen
            
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
            return newCompetition.pinInBackground()
        }).continueWithSuccessBlock({
            (task: BFTask!) -> AnyObject! in
            println("successfully stored new competition")
            return nil
        })
    }
    
    func updateCompetitionForGallery(name: String!){
        println("gallery update called for gallery \(name)")
        
        let localGalleryQuery = PFQuery(className: "Gallery_local").fromLocalDatastore()
        localGalleryQuery.whereKey("name", equalTo: name)
        localGalleryQuery.getFirstObjectInBackground().continueWithBlock({
            (task: BFTask!) -> AnyObject! in
            
            let localGallery = task.result as PFObject!
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
                if localLatestCompetition == nil {
                    // first download of competition
                    println("first download of competition")
                    self.addNewCompetitionForGallery(name, competitionId: localGallery["latestCompetition"] as String!)
                    // start maintaining submissions list
                    return nil
                }
                
                if localLatestCompetition["competitionId"] as String != localGallery["latestCompetition"] as String {
                    // was local one in active state?
                    println("latest local competition is outdated")
                    if localLatestCompetition["active"] as Bool {
                        // TODO delete submission cache
                        println("user missed grace period of previous competition")
                    } else {
                        println("user has seen grace period of previous competition")
                        // TODO delete grace period cache
                    }
                    
                    if localGallery["competitionActive"] as Bool {
                        // new competition is active -- start a submissiosn cache
                        println("new competition is active")
                        self.addNewCompetitionForGallery(name, competitionId: localGallery["latestCompetition"] as String!)
                    } else {
                        // new competition is inactive -- start a grace period cache
                        println("new competition is already in grace period")
                        self.addNewCompetitionForGallery(name, competitionId: localGallery["latestCompetition"] as String!)
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
                            // we're still in active -- update photo list
                        } else {
                            println("competition went into grace period")
                            // delete submission cache and start grace period cache
                            localLatestCompetition["active"] = false
                            localLatestCompetition.pinInBackground()
                        }
                    } else {
                        // both local and remote copy in grace period
                        println("latest compeitition in grace period like last time we checked")
                    }
                }
                return nil
            })
        })
    }
}