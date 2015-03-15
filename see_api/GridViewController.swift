//
//  GridViewController.swift
//  see_api
//
//  Created by Pete Kim on 3/14/15.
//  Copyright (c) 2015 Pete Kim. All rights reserved.
//

import UIKit
import Parse

class GridViewController: UIViewController {
    
    private class GridCollectionViewController: UICollectionViewController {
        private let reuseIdentifier = "photoCell"
        private var photos = [UIImage]()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            //self.collectionView = self.view as? UICollectionView
            
            var query = PFQuery(className: "Submission")
            
            query.findObjectsInBackgroundWithBlock({
                (objects: [AnyObject]!, error: NSError!) in
           
                if error != nil {
                    println("error!")
                    println(error.userInfo?["error"])
                    return
                }
                
                println("\(objects.count) submissions retrieved")
                
                if let o = objects as? [PFObject] {
                    for object in o {
                        let uploader :PFUser = object["user"] as PFUser
                        let imageFile: PFFile = object["imageFile"] as PFFile
                        let text: String! = object["text"] as String!
                       
                        imageFile.getDataInBackgroundWithBlock({
                            (imageData: NSData!, error: NSError!) in
                            
                            println("imagedata retrieved")
                            
                            if error != nil {
                                println("error!")
                                println(error.userInfo?["error"])
                                return
                            }
                            
                            var thisImage: UIImage! = UIImage(data: imageData)
                            self.photos.append(thisImage)
                            self.collectionView?.reloadData()
                        })
                        
                        println("submission from: \(uploader.username), accompanying text: \(text)")
                    }
                }
                
            
            })
        }
        
        override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            println("number of items requested (currently \(photos.count))")
            return photos.count
        }
        
        override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as photoCell
            cell.backgroundColor = UIColor.blackColor()
            cell.imageView.image = self.photos[indexPath.row]
            // Configure the cell
            return cell
        }
    }
   
    
    @IBOutlet weak var collectionView: UICollectionView!
    private var collectionVC: GridCollectionViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = false
        
        self.collectionVC = GridCollectionViewController()
        self.collectionVC!.view = self.collectionView
        self.collectionView.delegate = self.collectionVC
        self.collectionView.dataSource = self.collectionVC
        self.collectionVC!.viewDidLoad()
    }
}