SpeakHerePH
===========

**Updating to iOS 7 of SpeakHere example using AVAudioSession**

This project is an updating of the example SpeakHere created by Apple for iOS devices. Exactly the version 2.5 (2012-09-10) in [developer.apple.com](https://developer.apple.com/library/ios/samplecode/SpeakHere/Introduction/Intro.html "SpeakHere Apple project")

The project made by Apple in 2012 used Audio Session, however Audio Session is deprecated in iOS 7. For that reason, I updated this project with AVAudioSession for iOS 7.0 SDK, so I eliminated these deprecated warnings.

*For further details, I modified the following classes:*

**SpeakHereController.m**

In summary in play method I set category for playback and the same way I set caterory for recording in record method. Also I updated to AVAudioSession in awakeFromNib and enterForeground methods. The deprecated code is commented if you want to see it. In commit "Updated to iOS 7 with AVAudioSession" you can see the changes made by me.

**AQRecorder.mm**

After I commented the deprecated code I get sample rate and number of channels using AVAudioSession in SetupAudioFormat method. In commit "Updated to iOS 7 with AVAudioSession" you can see the modified hunks.


***

* twitter: [@pedrohr99](https://twitter.com/pedrohr99 "twitter @pedrohr99")
* linkedIn: [pedrohr99](http://www.linkedin.com/in/pedrohr99 "linkedIn pedroh")
