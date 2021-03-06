/*

    File: SpeakHereController.mm
Abstract: n/a
 Version: 2.5

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2012 Apple Inc. All Rights Reserved.


*/

#import "SpeakHereController.h"
#import <AVFoundation/AVFoundation.h>
#include "CAXException.h"

@implementation SpeakHereController

@synthesize player;
@synthesize recorder;

@synthesize btn_record;
@synthesize btn_play;
@synthesize fileDescription;
@synthesize lvlMeter_in;
@synthesize playbackWasInterrupted;

@synthesize inBackground;

char *OSTypeToStr(char *buf, OSType t)
{
	char *p = buf;
	char str[4] = {0};
    char *q = str;
	*(UInt32 *)str = CFSwapInt32(t);
	for (int i = 0; i < 4; ++i) {
		if (isprint(*q) && *q != '\\')
			*p++ = *q++;
		else {
			sprintf(p, "\\x%02x", *q++);
			p += 4;
		}
	}
	*p = '\0';
	return buf;
}

-(void)setFileDescriptionForFormat: (CAStreamBasicDescription)format withName:(NSString*)name
{
	char buf[5];
	const char *dataFormat = OSTypeToStr(buf, format.mFormatID);
	NSString* description = [[NSString alloc] initWithFormat:@"(%u ch. %s @ %g Hz)", (unsigned int)(format.NumberChannels()), dataFormat, format.mSampleRate, nil];
	fileDescription.text = description;
	[description release];	
}

#pragma mark Playback routines

-(void)stopPlayQueue
{
	player->StopQueue();
	[lvlMeter_in setAq: nil];
	btn_record.enabled = YES;
}

-(void)pausePlayQueue
{
	player->PauseQueue();
	playbackWasPaused = YES;
}

- (void)stopRecord
{
	// Disconnect our level meter from the audio queue
	[lvlMeter_in setAq: nil];
	
	recorder->StopRecord();
	
	// dispose the previous playback queue
	player->DisposeQueue(true);

	// now create a new queue for the recorded file
	recordFilePath = (CFStringRef)[NSTemporaryDirectory() stringByAppendingPathComponent: @"recordedFile.caf"];
	player->CreateQueueForFile(recordFilePath);
		
	// Set the button's state back to "record"
	btn_record.title = @"Record";
	btn_play.enabled = YES;
}

- (IBAction)play:(id)sender
{
    NSError *error = nil;
    
    // setting playback category for listen to audio track without mixing audio from other apps
    try {
        // an intance of AVAudioSession class
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        // it changes category for listen to track
        [session setCategory:AVAudioSessionCategoryPlayback error:&error];
        XThrowIfError((int)error.code, "couldn't set playback audio category");
        
        // the session must be active
        [session setActive:YES error:&error];
        XThrowIfError((int)error.code, "couldn't set audio session active in playing\n");
        
    } catch (CAXException e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
    }
    
    if (!error) {
        // play
        if (player->IsRunning())
        {
            if (playbackWasPaused) {
                OSStatus result = player->StartQueue(true);
                playbackWasPaused = NO;
                if (result == noErr)
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:self];
            }
            else
                [self stopPlayQueue];
        }
        else
        {
            OSStatus result = player->StartQueue(false);
            if (result == noErr)
                [[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:self];
        }
    }
}

- (IBAction)record:(id)sender
{
	if (recorder->IsRunning()) // If we are currently recording, stop and save the file.
	{
		[self stopRecord];
	}
	else // If we're not recording, start.
	{
        // an intance of AVAudioSession class
        AVAudioSession *session = [AVAudioSession sharedInstance];
        // we do not want to allow recording if input is not available
        [session requestRecordPermission:^(BOOL granted) {
            if (granted) {
                
                // microphone has permision to be used in this app
                NSError *error;
                // setting the category will also request access from the user
                [session setCategory:AVAudioSessionCategoryRecord error:&error];
                if (error)
                    NSLog(@"Couldn't set record audio category. Error=%ld", (long)error);
                
                [session setActive:YES error:&error];
                if (error)
                    NSLog(@"AVAudioSession setActive:YES failed in recording. Erorr=%ld", (long)error);
                
            }else {
                // Handle failure
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Microphone"
                                                                    message:@"Its access is denied"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                });
            }
        }];
        
        if (session.inputAvailable) {
            
            btn_play.enabled = NO;
            
            // Set the button's state to "stop"
            btn_record.title = @"Stop";
            
            // Start the recorder
            recorder->StartRecord(CFSTR("recordedFile.caf"));
            
            [self setFileDescriptionForFormat:recorder->DataFormat() withName:@"Recorded File"];
            
            // Hook the level meter up to the Audio Queue for the recorder
            [lvlMeter_in setAq: recorder->Queue()];
        }
	}
}

#pragma mark AudioSession listeners
void interruptionListener(	void *	inClientData,
							UInt32	inInterruptionState)
{
	SpeakHereController *THIS = (SpeakHereController*)inClientData;
	if (inInterruptionState == kAudioSessionBeginInterruption)
	{
		if (THIS->recorder->IsRunning()) {
			[THIS stopRecord];
		}
		else if (THIS->player->IsRunning()) {
			//the queue will stop itself on an interruption, we just need to update the UI
			[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueStopped" object:THIS];
			THIS->playbackWasInterrupted = YES;
		}
	}
	else if ((inInterruptionState == kAudioSessionEndInterruption) && THIS->playbackWasInterrupted)
	{
		// we were playing back when we were interrupted, so reset and resume now
		THIS->player->StartQueue(true);
		[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueResumed" object:THIS];
		THIS->playbackWasInterrupted = NO;
	}
}

void propListener(	void *                  inClientData,
					AudioSessionPropertyID	inID,
					UInt32                  inDataSize,
					const void *            inData)
{
	SpeakHereController *THIS = (SpeakHereController*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		CFDictionaryRef routeDictionary = (CFDictionaryRef)inData;			
		//CFShow(routeDictionary);
		CFNumberRef reason = (CFNumberRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
		SInt32 reasonVal;
		CFNumberGetValue(reason, kCFNumberSInt32Type, &reasonVal);
		if (reasonVal != kAudioSessionRouteChangeReason_CategoryChange)
		{
			/*CFStringRef oldRoute = (CFStringRef)CFDictionaryGetValue(routeDictionary, CFSTR(kAudioSession_AudioRouteChangeKey_OldRoute));
			if (oldRoute)	
			{
				printf("old route:\n");
				CFShow(oldRoute);
			}
			else 
				printf("ERROR GETTING OLD AUDIO ROUTE!\n");
			
			CFStringRef newRoute;
			UInt32 size; size = sizeof(CFStringRef);
			OSStatus error = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute);
			if (error) printf("ERROR GETTING NEW AUDIO ROUTE! %d\n", error);
			else
			{
				printf("new route:\n");
				CFShow(newRoute);
			}*/

			if (reasonVal == kAudioSessionRouteChangeReason_OldDeviceUnavailable)
			{			
				if (THIS->player->IsRunning()) {
					[THIS pausePlayQueue];
					[[NSNotificationCenter defaultCenter] postNotificationName:@"playbackQueueStopped" object:THIS];
				}		
			}

			// stop the queue if we had a non-policy route change
			if (THIS->recorder->IsRunning()) {
				[THIS stopRecord];
			}
		}	
	}
	else if (inID == kAudioSessionProperty_AudioInputAvailable)
	{
		if (inDataSize == sizeof(UInt32)) {
			UInt32 isAvailable = *(UInt32*)inData;
			// disable recording if input is not available
			THIS->btn_record.enabled = (isAvailable > 0) ? YES : NO;
		}
	}
}
				
#pragma mark Initialization routines
- (void)awakeFromNib
{		
	// Allocate our singleton instance for the recorder & player object
	recorder = new AQRecorder();
	player = new AQPlayer();
    
    /*
     * Code deprecated in iOS 7
	OSStatus error = AudioSessionInitialize(NULL, NULL, interruptionListener, self);
	if (error) printf("ERROR INITIALIZING AUDIO SESSION! %d\n", (int)error);
	else 
	{
		UInt32 category = kAudioSessionCategory_PlayAndRecord;	
		error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
		if (error) printf("couldn't set audio category!");
									
		error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self);
		if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %d\n", (int)error);
		UInt32 inputAvailable = 0;
		UInt32 size = sizeof(inputAvailable);
		
		// we do not want to allow recording if input is not available
		error = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &inputAvailable);
		if (error) printf("ERROR GETTING INPUT AVAILABILITY! %d\n", (int)error);
		btn_record.enabled = (inputAvailable) ? YES : NO;
		
		// we also need to listen to see if input availability changes
		error = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioInputAvailable, propListener, self);
		if (error) printf("ERROR ADDING AUDIO SESSION PROP LISTENER! %d\n", (int)error);

		error = AudioSessionSetActive(true); 
		if (error) printf("AudioSessionSetActive (true) failed");
	}
     */
    
    try {
        // an intance of AVAudioSession class
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        // notification for interruption handler
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:session];
        
        // notification for route change handler
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRouteChange:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:session];
    } catch (CAXException e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
    }
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackQueueStopped:) name:@"playbackQueueStopped" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackQueueResumed:) name:@"playbackQueueResumed" object:nil];

	UIColor *bgColor = [[UIColor alloc] initWithRed:.39 green:.44 blue:.57 alpha:.5];
	[lvlMeter_in setBackgroundColor:bgColor];
	[lvlMeter_in setBorderColor:bgColor];
	[bgColor release];
	
	// disable the play button since we have no recording to play yet
	btn_play.enabled = NO;
	playbackWasInterrupted = NO;
	playbackWasPaused = NO;
    
    [self registerForBackgroundNotifications];
}

# pragma mark Notification routines
- (void)playbackQueueStopped:(NSNotification *)note
{ 
	btn_play.title = @"Play";
	[lvlMeter_in setAq: nil];
	btn_record.enabled = YES;
}

- (void)playbackQueueResumed:(NSNotification *)note
{
	btn_play.title = @"Stop";
	btn_record.enabled = NO;
	[lvlMeter_in setAq: player->Queue()];
}

#pragma mark background notifications
- (void)registerForBackgroundNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resignActive)
												 name:UIApplicationWillResignActiveNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(enterForeground)
												 name:UIApplicationWillEnterForegroundNotification
											   object:nil];
}

- (void)resignActive
{
    if (recorder->IsRunning()) [self stopRecord];
    if (player->IsRunning()) [self stopPlayQueue];
    inBackground = true;
}

- (void)enterForeground
{
    /*
     * Code deprecated in iOS 7
    OSStatus error = AudioSessionSetActive(true);
    if (error) printf("AudioSessionSetActive (true) failed");
     */

    // activating AVAudioSession
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError* error = nil;
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"AVAudioSession setActitve:YES failed in enterForeground method");
    }

    
	inBackground = false;
}

#pragma mark Cleanup
- (void)dealloc
{
	[btn_record release];
	[btn_play release];
	[fileDescription release];
	[lvlMeter_in release];
	
	delete player;
	delete recorder;
	
	[super dealloc];
}

@end
