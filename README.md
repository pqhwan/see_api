# see_api
##### April: Feel free to add whatever you find out (or any questions or concerns) to this readme!
---
flat-api app for testing technical solutions for see.


### [GENERAL QUESTIONS & COMMENTS]
---
+ What object classes will we need for this? What attributes will they have? (i.e. "what is our database schema?" except that we don't need one) This is one angle we can use to solidify our system design.
+ Interval of time between the end of competition and the beginning of the next one.
+ What variables should we have left for cloudCode to designate?
	+ size of a competition (range)
	+ amount of prize money
	+ entrance fee

### [IN-APP PURCHASE]
---
##### Updates & todos
+ Refer to Parse doc on iOS SDK
+ let's see it work on a page
+ is there a way to test this api without involving actual money?

### [CLOSING VOTE & ANNOUNCING WINNER]
---
##### Updates & todos
~~*Likely to turn out to be the hairies part of this development.*~~

~~**Major concern: there should not be any possibility of race condition in the closing of competitions and announcement of winners.**~~

**SOLUTION FOUND: Cloud Code has all we need**

##### "Command"
+ ~~One thing we're pretty certain about in solving this problem is that we need to store some "logic" on the server-side as well. Candidates for implmenting this:~~
	1. ~~Python or Node daemon on EC2 giving commands via REST API.~~
	2. Cloudcode on Parse.
	3. ~~(slightly ridiculous) One iPhone to rule them all (user with super privileges).~~
	
+ ~~Do your research to see if any of these can perform all the tasks necessary. Also consider flexibility of adding new features.~~ DONE

+ *Parse Cloudcode will suffice!*
    + Cloudcode has access to all data on Parse backend. 
    + You can trigger push notifications on Cloudcode.
    + Cloud "jobs" can be scheduled for a specific time and with frequency.
    + one concern: how to close voting?
        + all votes will have "createdAt" time. We can just count the ones made before 12:00AM. 
        	+ Isn't this too heavy on the backend though?
        + Another option is to have the scheduled job block vote uploads. Is there a way to block save() operations for a specific class of Parse objects?
        	+ We can use the beforeSave hook on the votes object
        	+ e.g. Normally, ```Parse.Cloud.define(votingIsOpen() = {return true;})```, but scheduled job calls ```Parse.Cloud.define(votingIsOpen() = {return false;})```. Finally, the before-save hook on the vote object only accepts votes when votingIsClosed() returns true. (don't forget to set it back to original when another competition begins!)
    + We need other types of jobs, too 
    	+ like "competition cleanup & reboot"
       	

##### Closing vote scenario run
1. Client app stops users from voting any further past deadline.	+ Blocking save() on vote objects on the server theoretically suffices, but we don't want the server to be overloaded by last-minute votes
	+ Timezone issue: how to implement the notion of "absolute time".
	+ Edge case: some users' phone clocks might be slightly off (in relation to the server's clock).
	+ if user has the app on during this time, display a message informing the user that the competition has ended and that the winner will be announced shortly.
2. Server refuses votes once its past deadline.
	+ ~~EC2 command: how do we do this? *command* sends signal that somehow puts Parse in to "votecount mode"?~~
	+ CloudCode command: Count valid votes, 
3. Server announces the winner through push notification
	+ server sends minimal information, and clients create an announcement based on it. (saves bandwidth) **POSSIBLE BOTTLENECK**.
	

##### Receiving Push notification
1. Buy Apple dev license for $99
2. Configure the app to enable push notification
3. We don't need anything fancy just yet: have everyone subscribe to a "global" channel.

##### Sending Push notification
1. ~~REST API: have a script running on some remote machine (EC2?) that makes an REST API call to Parse server.~~
2. Use cloud code!


### [HOW TO DEAL WITH PHOTOS]
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
+ Photo dimension issues
+ Creating & storing thumbnails
	+ parse cloud code offers a module for creating thumbnails for uploaded images
+ Deleting photos
	+ Should we delete photos from competitions except for the winners'? Yes. Absolutely.

##### Treating winners' photos differently


### [PAYING THE WINNER]
---
+ What do you need to make a payment to the winner?
+ What information do we need from the users?
