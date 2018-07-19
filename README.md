# Slide [![Discord](https://img.shields.io/discord/407573578985242635.svg)](https://discord.gg/hVWAY8A)

<img src="/slide_ios_rounded.png" align="left"
width="150"
    hspace="10" vspace="10">

Slide is an open-source, ad-free Reddit browser for iOS. It is based around
the [Reddift](https://github.com/sonsongithub/reddift) Reddit API wrapper.

Slide is not yet avaliable for download on the App Store, but is currently going through Alpha testing through TestFlight. For more information regarding availability, feel free to join us on [the subreddit](https://www.reddit.com/r/slide_ios)  



## Contributing

### Getting started
To get started with Slide iOS development, you need to set up Cocoapods integration and open the Coacoapods workspace, not the default xcworkspace. **NOTE: You must open the .xcworkspace file instead of the .xcodeproj file for dependencies to load. If you are having issues with Pods or are setting up the Slide repository for the first time, try the steps below.**

Below are the steps to getting started:

    1. Terminal: sudo gem install cocoapods
    2. Safari: Downloaded Slide from GitHub (clone or download -> Download Zip)
    3. Terminal: cd Downloads/Slide-iOS-Master/
    4. Terminal: pod install
    5. Open "Slide for Reddit.xcworkspace" through finder
    
### If you are having trouble building on XCode 10 or MacOS Mojave

Try running "chmod 666 Pods/Realm/include/RLMPlatform.h" from terminal in the project root directory

### If you don't have a paid Apple Developer account and you get warnings about iCloud entitlements

Select "none" for your team, go to the "Capabilities" section of the project build settings, and disable iCloud and IAP support. Then, add yourself back as the team and build!

If you still run into problems, feel free to shoot me a message on Reddit or Discord (above)

### What needs to be done
Slide is in beta, and there are issues that need to be resolved and some feature additions that need to be integrated before the public version 1 release. Any issues are fair game, but any issue with the "Help Wanted" tag is an issue that I have not started on or that should be straightforward to implement with a single PR! If you have any questions or want to be pointed in the right direction, feel free to send me a PM on Reddit to /u/ccrama, or join us on Discord (top banner)!

### Issues

In any project, it's likely that a few bugs will slip through the cracks, so it
helps greatly if people document any bugs they find to ensure that they get
fixed promptly.

You can view a list of known issues and feature requests using [the issue tracker](
https://github.com/ccrama/Slide-ios/issues). If you don't see your issue (or you
aren't sure) feel free to [submit it!](https://github.com/ccrama/Slide-ios/issues/new)

Where appropriate, a screenshot works wonders to help us see exactly what the
issue is. You can upload screenshots directly using the GitHub issue tracker or
by attaching a link (to Imgur, for example), whichever is easier for you.

### Code

If you are a developer and wish to contribute to the app please fork the project
and submit a pull request.

If you have any questions, feel free to message me on Discord or
[drop me a message](https://www.reddit.com/message/compose/?to=ccrama) on Reddit.

## Changes

For a detailed look at changes to the app you can, [view individual
commits](https://github.com/ccrama/Slide-ios/commits/master).

## Licensing

Slide is licensed under the [Apache 2 License.](LICENSE)

If you find Slide's code useful or you use code from this repository, feel free to let me know!
