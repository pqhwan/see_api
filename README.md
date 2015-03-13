# see_api
##### April: Feel free to add whatever you find out to this readme!
---
flat-api app for testing technical solutions for see.


### [GENERAL QUESTIONS & COMMENTS]
---
+ what object classes will we need for this? What attributes will they have? (i.e. "what is our database schema?" except that we don't need one)

### [IN-APP PURCHASE]
---

+ Refer to Parse doc on iOS SDK
+ let's see it work on a page
+ is there a way to test this api without involving actual money?

### [PUSH NOTIFICATION]
---
**Major concern: there should not be any possibility of race condition in the closing of competitions and announcement of winners**

+ parse cloud code


### [PHOTOS]
---
##### Parse objects and class
+ what should be in the "photo" object we store on Parse?
	+ reference to full-sized photo image
	+ reference to thumbnail image
	+ should thumbnail be it's own object? yes.
+ what about the "thumbnail" object?
	+ reference to thumbnail image
	+ reference to original photo object

##### Downloading, caching and viewing photos
+ Downloading photos for this week's competition
	+ Downloading thumbnails for gridview
	+ Downloading full-sized photos for detailview
	+ what if user is offline here?
	
+ Caching photos for this week's competition
	+ Caching initial download
	+ Should we cache full-sized photos or thumbnails?
	+ Identifying and selectively downloading newly-updated photos that aren't in cache yet
	+ what if user has no space for caching? how would we know and how should we respond?
		+ Is there something like didReceiveMemoryWarning for disk space?
	
+ Updating photos to include newly-submitted photos
	+ get latest photo in currently stored list & ask for photos created after that.
	+ what if user is offline here?

##### Uploading and storing photos
+ photo dimension issues
+ creating & storing thumbnails
	+ parse cloud code offers a module for creating thumbnails for uploaded images


### [VENMO PAYMENT]
---
##### Paying the winner
+ What do you need to make a payment to the winner?
+ What information do we need from the users?