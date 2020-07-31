# Slide for Reddit [![iOS App Store](https://img.shields.io/itunes/v/1260626828.svg)](https://itunes.apple.com/us/app/slide-for-reddit/id1260626828) [![Reddit](https://img.shields.io/badge/reddit-%2Fr%2Fslide__ios-brightgreen.svg)](https://www.reddit.com/r/slide_ios) [![Discord](https://img.shields.io/discord/407573578985242635.svg)](https://discord.gg/hVWAY8A)  

<img src="/slide_ios_rounded.png" align="left" width="150" hspace="10" vspace="10">

Slide is a powerful open-source, ad-free, Swift-based Reddit browser for iOS. Feel free to join us on [the official subreddit](https://www.reddit.com/r/slide_ios) for discussion or requests!

<a href="https://apps.apple.com/us/app/slide-for-reddit/id1260626828?mt=8" style="display:inline-block;overflow:hidden;background:url(https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2018-08-20&kind=iossoftware&bubble=ios_apps) no-repeat;width:135px;height:40px;"></a>

<br>
<br>
<br>
<br>

## Getting started

To get started with Slide iOS development, you need to set up CocoaPods integration and open the Coacoapods workspace, not the default xcworkspace. **NOTE: You must open the .xcworkspace file instead of the .xcodeproj file for dependencies to load. If you are having issues with Pods or are setting up the Slide repository for the first time, try the steps below.**

Below are the steps to getting started:

1. Clone this repo and open the Terminal
2. In Terminal, run `pod install`
3. Open "Slide for Reddit.xcworkspace" through Finder
4. Modify [/scripts/install-filter.sh](/scripts/install-filter.sh) with the information it asks for, then run it from the repo root directory (`sh ./scripts/install-filter.sh`). Once done, your developer info will automatically replace the defaults (even if you change branches!), and you can't accidentally overwrite the defaults. (If you don't want to do this, just put a new value in the USR_DOMAIN variable in the main target's Build Settings, then modify the signing info yourself. Make sure you don't commit changes to the signing info.)

### If you are having trouble building on XCode 10 or MacOS Mojave

Try running `chmod 666 Pods/Realm/include/RLMPlatform.h` from Terminal in the project root directory.


### If you don't have a paid Apple Developer account and you get warnings about iCloud entitlements

Select "none" for your team, go to the "Capabilities" section of the project build settings, and disable iCloud and IAP support. Then, add yourself back as the team and build!

If you still run into problems, feel free to shoot me a message on Reddit or Discord (above).


## What needs to be done

Any issues are fair game, but any issue with the "Help Wanted" or "Enhancement" tags are issues that we would particularly love help with. If you have any questions or want to be pointed in the right direction, feel free to send me a PM on Reddit to [/u/ccrama](https://www.reddit.com/u/ccrama), or join us on [Discord](https://discord.gg/hVWAY8A)!


## Issues

In any project, it's likely that a few bugs will slip through the cracks, so it helps greatly if people document any bugs they find to ensure that they get fixed promptly.

You can view a list of known issues and feature requests using [the issue tracker](https://github.com/ccrama/Slide-ios/issues). If you don't see your issue (or you aren't sure) feel free to [submit it](https://github.com/ccrama/Slide-ios/issues/new)!

Where appropriate, a screenshot works wonders to help us see exactly what the issue is. You can upload screenshots directly using the GitHub issue tracker or by attaching a link (to Imgur, for example); whichever is easier for you.


## Code

If you are a developer and wish to contribute to the app, please fork the project and submit a pull request.

If you have any questions, feel free to message me on Discord or [drop me a message](https://www.reddit.com/message/compose/?to=ccrama) on Reddit.


## Changes

For a detailed look at changes to the app you can [view individual commits](https://github.com/ccrama/Slide-ios/commits/master).


## Licensing

Slide is licensed under the [Apache 2 License](LICENSE).

If you find Slide's code useful or you use code from this repository, feel free to let me know!
