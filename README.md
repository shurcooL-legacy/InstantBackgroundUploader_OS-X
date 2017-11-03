Instant Background Uploader (OS X)
==================================

A simple menu bar OS X app to convert a local image (in the clipboard) to its online URL (in the clipboard), uploaded to ImageShack.us.

It can also convert a local image (in the clipboard) to an \<img\> tag with inline [data URI](https://en.wikipedia.org/wiki/Data_URI_scheme) encoded representation.

Downloads
---------

[Download Instant Background Uploader](https://dmitri.shuralyov.com/projects/InstantBackgroundUploader_OS-X/downloads/InstantBackgroundUploader_OS-X.zip) for OS X

Screenshots
-----------

![](https://dmitri.shuralyov.com/projects/InstantBackgroundUploader_OS-X/images/InstantBackgroundUploader1.png)

![](https://dmitri.shuralyov.com/projects/InstantBackgroundUploader_OS-X/images/InstantBackgroundUploader2b.png)

A previous version used Matt Gemmell's MAAttachedWindow for notifications, instead of Mountain Lion's Notification Center.

![](https://dmitri.shuralyov.com/projects/InstantBackgroundUploader_OS-X/images/InstantBackgroundUploader2.png)

Requirements
------------

-	OS X 10.8 Mountain Lion (it uses Notification Center)

It's easy to make it (dynamically) fall back to MAAttachedWindow for previous versions of OS X. But I'm unlikely to do it myself, since I don't have access to an older OS X version right now, and trying to build something blindly isn't efficient. If you can do it, that'd be great. Please submit a pull request and I'll merge it.

Attribution
-----------

Includes MAAttachedWindow code by [Matt Gemmell](http://mattgemmell.com/). Thank you, Matt Gemmell.

License
-------

-	[MIT License](http://opensource.org/licenses/mit-license.php)
