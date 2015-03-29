//
//  DisplayFunctions.swift
//  see_api
//
//  Created by Pete Kim on 3/27/15.
//  Copyright (c) 2015 Pete Kim. All rights reserved.
//

import Foundation
import Parse


func printObject(object: PFObject, className: String!) {
  switch className {
  case "Gallery":
    printGallery(object)
  case "Gallery_local":
    printGalleryLocal(object)
  case "Competition":
    printCompetition(object)
  case "Competition_local":
    printCompetitionLocal(object)
  case "Submission":
    printSubmission(object)
  case "Submission_local":
    printSubmissionLocal(object)
  default:
    basicPrinter(object)
  }
}


func printGallery(object: PFObject) {
  println("Gallery object---")
  basicPrinter(object)
  
  let name = object["name"] as String!
  let latestCompetition = object["latestCompetition"] as String!
  let competitionActive = object["competitionActive"] as Bool!
  
  println("name: \(name)")
  println("latestCompetition: \(latestCompetition)")
  println("competitionActive: \(competitionActive)")
}

func printGalleryLocal(object: PFObject) {
  println("Gallery_local object---")
  basicPrinter(object)

  let galleryId = object["galleryId"] as String!
  let name = object["name"] as String!
  let latestCompetition = object["latestCompetition"] as String!
  let competitionActive = object["competitionActive"] as Bool!
  
  println("name: \(name)")
  println("latestCompetition: \(latestCompetition)")
  println("competitionActive: \(competitionActive)")
}

func printCompetition(object: PFObject) {
  println("Competition object---")
  basicPrinter(object)
  
  let endDate = object["endDate"] as NSDate!
  let active = object["active"] as Bool!
  let gallery = object["gallery"] as String!
  
  println("endDate: \(endDate)")
  println("active: \(active)")
  println("gallery: \(gallery)")
}

func printCompetitionLocal(object: PFObject) {
  println("Comeptition_local object---")
  basicPrinter(object)
  
  let competitionId = object["competitionId"] as String!
  let galleryId = object["galleryId"] as String!
  let active = object["active"] as Bool!
  let endDate = object["endDate"] as NSDate!
  let maintained = object["maintained"] as Bool!

  println("competitionId: \(competitionId)")
  println("galleryId: \(galleryId)")
  println("active: \(active)")
  println("endDate: \(endDate)")
  println("maintained: \(maintained)")
}

func printSubmission(object: PFObject) {
  println("Submission object---")
  basicPrinter(object)
  
  let competitionId = object["competitionId"] as String!
  let userId = object["userId"] as String!
  let description = object["description"] as String!
  println("competitionId: \(competitionId)")
  println("userId: \(userId)")
  println("description: \(description)")
}
func printSubmissionLocal(object: PFObject) {
  println("Submission_local object---")
  basicPrinter(object)

  let submissionId = object["submissionId"] as String!
  let submissionCreatedAt = object["submissionCreatedAt"] as NSDate!
  let competitionId = object["competitionId"] as String!
  let userId = object["userId"] as String!
  let description = object["description"] as String!
  let file = object["file"] as PFFile!
  
  println("competitionId: \(competitionId)")
  println("userId: \(userId)")
  println("description: \(description)")
  println("file: \(file)")
}


func basicPrinter(object: PFObject!){
  println("objectId: \(object.objectId)")
  println("createdAt: \(object.createdAt)")
  println("updatedAt: \(object.updatedAt)")
}

