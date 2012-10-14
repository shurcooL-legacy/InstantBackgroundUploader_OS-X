//
//  AppDelegate.m
//  StatusMenuAppTest
//
//  Created by Dmitri Shuralyov on 12-03-06.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "MAAttachedWindow.h"

#define DECISION_KEEP_NOTIFICATIONS_IN_NC 0

@implementation ItemAndTitle
@end

@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application

	// Set self as NSUserNotificationCenter delegate
	[[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate: self];

	// If we were opened from a user notification, do the corresponding action
	{
		NSUserNotification * launchNotification = [[aNotification userInfo] objectForKey: NSApplicationLaunchUserNotificationKey];
		if (launchNotification)
			[self userNotificationCenter: nil didActivateNotification: launchNotification];
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
#if DECISION_KEEP_NOTIFICATIONS_IN_NC
	// Clear all notifications
	[[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
#endif
}

- (IBAction)UploadImageAsPng:(id)sender
{
	//while (!(nil != conversionPngThread && [conversionPngThread isFinished]))
	while (!targetImageDataExistsPng)
	{
		usleep(50);
	}

	requestedUploadAction = 1;
	[self UploadImage];
}

- (IBAction)UploadImageAsJpg:(id)sender
{
	//while (!(nil != conversionJpgThread && [conversionJpgThread isFinished]))
	while (!targetImageDataExistsJpg)
	{
		usleep(50);
	}

	requestedUploadAction = 2;
	[self UploadImage];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
#if DECISION_KEEP_NOTIFICATIONS_IN_NC
	NSString * imageUrl;
	if (   nil != [notification userInfo]
		&& nil != (imageUrl = [[notification userInfo] objectForKey: @"ImageUrl"])
		&& [imageUrl length] > 0)
	{}
	else
	{
		[center removeDeliveredNotification: notification];
	}
#else
	[center removeDeliveredNotification: notification];
#endif
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
	return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
#if DECISION_KEEP_NOTIFICATIONS_IN_NC
	[center removeDeliveredNotification: notification];
#endif

	//NSLog(@"%ld", [notification activationType]);
	//NSLog(@"%@", notification);

	NSString * imageUrl;
	if (   nil != [notification userInfo]
		&& nil != (imageUrl = [[notification userInfo] objectForKey: @"ImageUrl"])
		&& [imageUrl length] > 0)
	{
		// Set clipboard contents to a string
		NSPasteboard * pb = [NSPasteboard generalPasteboard];
		NSArray * types = [NSArray arrayWithObjects:NSStringPboardType, nil];
		[pb declareTypes:types owner:self];
		[pb setString:imageUrl forType:NSStringPboardType];

		// Open it in a browser
		[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: imageUrl]];
	}
	else
	{}
}

- (IBAction)UploadImageAsNotificationCenter:(id)sender
{
	/*NSString * imageUrl = @"http://img209.imageshack.us/img209/8207/imageel.png";
	//NSString * imageUrl = @"";
	NSString * failReason;

	[self displayUserNotification: imageUrl failReason: failReason];*/
}

- (IBAction)UploadImage
{
	NSData * data = nil;
	if (0 == requestedUploadAction)
	{
		return;
	}
	else if (1 == requestedUploadAction && targetImageDataExistsPng)
	{
		data = targetImageDataPng;
	}
	else if (2 == requestedUploadAction && targetImageDataExistsJpg)
	{
		data = targetImageDataJpg;
	}
	else
	{
		NSLog(@"Error, something went wrong in UploadImage\n");
		return;
	}

	if (nil != data)
	{
		// Upload image
		NSString *urlString = @"http://www.imageshack.us/upload_api.php";
		NSString *filename;
		NSString *type;
		if (1 == requestedUploadAction) {
			filename = @"Image.png";
			type = @"image/png";
		} else if (2 == requestedUploadAction) {
			filename = @"Image.jpg";
			type = @"image/jpeg";
		}
		NSString * key = @"12DEFKTYa5517607af7de06ec6272205d57a9cf4";
		NSMutableURLRequest * request= [[NSMutableURLRequest alloc] init];
		[request setURL:[NSURL URLWithString:urlString]];
		[request setHTTPMethod:@"POST"];
		NSString *boundary = @"---------------------------14737809831466499882746641449";
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
		[request addValue:contentType forHTTPHeaderField: @"Content-Type"];
		NSMutableData *postbody = [NSMutableData data];
		[postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"key\"\r\n\r\n%@\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"fileupload\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", type] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[NSData dataWithData:data]];
		[postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[request setHTTPBody:postbody];
		
		NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
		NSString * returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
		//NSLog(@"%@\n", returnString);

		// Try to parse the <image_link> out of the response
		NSString * imageUrl = @"";
		do
		{
			NSRange StartRange = [returnString rangeOfString:@"<image_link>" options:NSCaseInsensitiveSearch];
			if (StartRange.location == NSNotFound) break;
			NSRange EndRange = [returnString rangeOfString:@"</image_link>" options:NSCaseInsensitiveSearch range:NSMakeRange(StartRange.location + StartRange.length, [returnString length] - (StartRange.location + StartRange.length))];
			if (EndRange.location == NSNotFound) break;
			imageUrl = [returnString substringWithRange:NSMakeRange(StartRange.location + StartRange.length, EndRange.location - (StartRange.location + StartRange.length))];
		}
		while (false);
		//NSLog(@"imageUrl: >%@<\n", imageUrl);

		// If successfully uploaded
		if ([imageUrl length] > 0)
		{
			// Set clipboard contents to a string
			NSPasteboard * pb = [NSPasteboard generalPasteboard];
			NSArray * types = [NSArray arrayWithObjects:NSStringPboardType, nil];
			[pb declareTypes:types owner:self];
			[pb setString:imageUrl forType:NSStringPboardType];

			// Display a popup balloon
			//[self toggleAttachedWindowAtPoint:notificationPosition message:@"Image uploaded successfully,\nits URL is now in your Clipboard." withUrl:[NSURL URLWithString:imageUrl]];
			[self displayUserNotification: imageUrl failReason: nil];
		}
		else
		{
			NSLog(@"Upload failed.\n>%@<\n", returnString);

			// Display a popup balloon
			//[self toggleAttachedWindowAtPoint:notificationPosition message:[NSString stringWithFormat:@"Image upload failed.\n%@", [returnString substringFromIndex: 8]] withUrl:nil];
			[self displayUserNotification: nil failReason: [returnString substringFromIndex: 8]];
		}

		requestedUploadAction = 0;
	}
}

- (void)displayUserNotification: (NSString *)imageUrl failReason: (NSString *)failReason
{
	NSUserNotification * notification = [[NSUserNotification alloc] init];
	if (   nil != imageUrl
		&& [imageUrl length] > 0)
	{
		[notification setTitle: @"Image Uploaded"];
		[notification setInformativeText: @"Its URL is now in your Clipboard."];
		[notification setUserInfo: [NSDictionary dictionaryWithObject: imageUrl forKey: @"ImageUrl"]];
	}
	else
	{
		[notification setTitle: @"Image Upload Failed"];
		[notification setInformativeText: failReason];
	}
	[notification setSoundName: NSUserNotificationDefaultSoundName];

	NSUserNotificationCenter * center = [NSUserNotificationCenter defaultUserNotificationCenter];
	[center deliverNotification: notification];
}

- (void)toggleAttachedWindowAtPoint:(NSPoint)pt message:(NSString *)message withUrl:(NSURL *)Url
{
	if (nil != attachedWindow && ![attachedWindow isVisible])
	{
		attachedWindow = nil;
	}

    // Attach/detach window.
    if (nil == attachedWindow)
	{
		//NSLog(@"Created window at %f, %f\n", pt.x, pt.y);
        attachedWindow = [[MAAttachedWindow alloc] initWithView:view 
                                                attachedToPoint:pt 
                                                       inWindow:nil 
                                                         onSide:MAPositionBottom 
                                                     atDistance:5.0
														withUrl:Url];
        [textField setTextColor:[attachedWindow borderColor]];
		[textField setStringValue:message];
		//[textField sizeToFit];
        [attachedWindow makeKeyAndOrderFront:self];
    }
	else
	{
		[attachedWindow setAlphaValue:1.0];
	}

	// Stop old timers
	if (nil != closeTimer)
	{
		[closeTimer invalidate];
		closeTimer = nil;
	}
	if (nil != repeatingTimer)
	{
		[repeatingTimer invalidate];
		self->repeatingTimer = nil;
	}

	NSTimer * timer = [NSTimer scheduledTimerWithTimeInterval:3.0
									 target:self
								   selector:@selector(closePopup)
								   userInfo:self
									repeats:NO];
	self->closeTimer = timer;
}

- (IBAction)closePopup
{
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.01
										target:self
									  selector:@selector(keepHidingPopup)
									  userInfo:nil
									   repeats:YES];
	self->repeatingTimer = timer;
}

- (IBAction)keepHidingPopup
{
	if ([attachedWindow alphaValue] > 0.02)
	{
		[attachedWindow setAlphaValue: [attachedWindow alphaValue] - 0.02];
	}
	else
	{
		if (nil != attachedWindow)
		{
			[attachedWindow orderOut:self];
			//[attachedWindow release];
			attachedWindow = nil;
		}
		
		// Stop old timers
		if (nil != closeTimer)
		{
			[closeTimer invalidate];
			closeTimer = nil;
		}
		if (nil != repeatingTimer)
		{
			[repeatingTimer invalidate];
			self->repeatingTimer = nil;
		}
	}
}

/*- (IBAction)openMenu:(id)sender
{
	//[statusItem popUpStatusItemMenu:statusMenu];
	
	// Display a popup balloon
	NSRect frame = [[[NSApp currentEvent] window] frame];
	NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
	[self toggleAttachedWindowAtPoint:pt message:@"Blah" withUrl:nil];
}*/

- (void)conversionPngThreadMethod
{
	if (1 == sourceImageDataType)
	{
		if ([conversionPngThread isCancelled])
		{
			return;
		}
		targetImageDataPng = sourceImageData;
		targetImageDataExistsPng = true;
	}
	else if (2 == sourceImageDataType)
	{
		NSBitmapImageRep * bitmap = [NSBitmapImageRep imageRepWithData: sourceImageData];
		NSData * data = [bitmap representationUsingType: NSPNGFileType properties: nil];
		if ([conversionPngThread isCancelled])
		{
			return;
		}
		targetImageDataPng = data;
		targetImageDataExistsPng = true;
	}
	
	ItemAndTitle * object = [ItemAndTitle new];
	object->item = uploadPngMenuItem;
	object->title = [NSString stringWithFormat:@"Upload Image from Clipboard (%i KiB)", [targetImageDataPng length] / 1024];
	[self performSelectorOnMainThread:@selector(changeMenuTitle:)withObject:object waitUntilDone:YES];
}

- (void)conversionJpgThreadMethod
{
	if (1 == sourceImageDataType || 2 == sourceImageDataType)
	{
		NSBitmapImageRep * bitmap = [NSBitmapImageRep imageRepWithData: sourceImageData];
		NSData * data = [bitmap representationUsingType: NSJPEGFileType properties: nil];
		if ([conversionJpgThread isCancelled])
		{
			return;
		}
		targetImageDataJpg = data;
		targetImageDataExistsJpg = true;
	}

	ItemAndTitle * object = [ItemAndTitle new];
	object->item = uploadJpgMenuItem;
	object->title = [NSString stringWithFormat:@"Upload Image from Clipboard as JPEG (%i KiB)", [targetImageDataJpg length] / 1024];
	[self performSelectorOnMainThread:@selector(changeMenuTitle:)withObject:object waitUntilDone:YES];
}

- (IBAction)changeMenuTitle:(ItemAndTitle *)object
{
	[object->item setTitle:object->title];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if ([item action] == @selector(UploadImageAsPng:))
	{
		// Update notificationPosition
		NSRect frame = [[[NSApp currentEvent] window] frame];
		notificationPosition = NSMakePoint(NSMidX(frame), NSMinY(frame));

		// Stop previous threads
		if (nil != conversionPngThread)
		{
			[conversionPngThread cancel];
		}
		if (nil != conversionJpgThread)
		{
			[conversionJpgThread cancel];
		}

		// Figure out clipboard contents
		NSPasteboard * pb = [NSPasteboard generalPasteboard];
		NSData * data;
		if (nil != (data = [pb dataForType: NSPasteboardTypePNG]))
		{
			sourceImageDataType = 1;
			sourceImageData = data;
			targetImageDataExistsPng = false;
			targetImageDataPng = nil;
			targetImageDataExistsJpg = false;
			targetImageDataJpg = nil;
		}
		else if (nil != (data = [pb dataForType: NSPasteboardTypeTIFF]))
		{
			sourceImageDataType = 2;
			sourceImageData = data;
			targetImageDataExistsPng = false;
			targetImageDataPng = nil;
			targetImageDataExistsJpg = false;
			targetImageDataJpg = nil;
		}
		else
		{
			sourceImageDataType = 0;
			sourceImageData = nil;
			targetImageDataExistsPng = false;
			targetImageDataPng = nil;
			targetImageDataExistsJpg = false;
			targetImageDataJpg = nil;
		}

		// If there is an image in clipboard, enable menu items
		if (0 != sourceImageDataType)
		{
			[item setTitle:@"Upload Image from Clipboard"];

			// Start conversion threads
			conversionPngThread = [[NSThread alloc] initWithTarget:self selector:@selector(conversionPngThreadMethod) object:nil];
			[conversionPngThread start];
			conversionJpgThread = [[NSThread alloc] initWithTarget:self selector:@selector(conversionJpgThreadMethod) object:nil];
			[conversionJpgThread start];

			return YES;
		}
		else
		{
			[item setTitle:@"No Image in Clipboard"];
			return NO;
		}
	}
	else if ([item action] == @selector(UploadImageAsJpg:))
	{
		[item setHidden: ![uploadPngMenuItem isEnabled]];
		[item setTitle:@"Upload Image from Clipboard as JPEG"];
		return YES;
	}

	return YES;
}

- (void)awakeFromNib
{
	attachedWindow = nil;
	closeTimer = nil;
	repeatingTimer = nil;

	sourceImageDataType = 0;
	sourceImageData = nil;
	targetImageDataExistsPng = false;
	targetImageDataPng = nil;
	targetImageDataExistsJpg = false;
	targetImageDataJpg = nil;
	
	conversionPngThread = nil;
	conversionJpgThread = nil;

	requestedUploadAction = 0;

	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	//[statusItem setTitle:@"Status"];
	NSImage * app_icon = [NSImage imageNamed:@"app_icon.ico"];
	[statusItem setImage:app_icon];
	[statusItem setHighlightMode:YES];

	[statusItem setMenu:statusMenu];
	/*[statusItem setAction:@selector(openMenu:)];
	[statusItem sendActionOn: NSLeftMouseDownMask];
	[statusItem setTarget:self];*/

	[statusItem setToolTip:@"Instant Background Uploader (0.005)"];
}

@end