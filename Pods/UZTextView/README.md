UZTextView
==========
Clickable and selectable text view for iOS

###What's UZTextView?
- UZTextView class implements implements the behavior for a scrollable, multiline, selectable, clickable text region. 
 The class supports the display of text using custom style and link information.
- Create subclass of the class and use UZTextView internal category methods if you want to expand the UZTextView class. For example, you have to override some methods of the class in order to add your custom UIMenuItem objects.
- You can use the Class on the UITableView cell and set custom style text using NSAttributedString class objects(like the following image).

![image](https://raw.github.com/sonsongithub/UZTextView/master/screenshot/UZTextView.gif)

###Supported attributes of NSAttributedString
- NSLinkAttributeName
- NSFontAttributeName
- NSStrikethroughStyleAttributeName
- NSUnderlineStyleAttributeName
- NSBackgroundColorAttributeName

###How to build
- Use build.sh. Automatically lib and header file generated at ./build/.
- UZTextView supports [CocoaPods](http://cocoapods.org/).

###Document
- See html/index.html

###License
- UZTextView is available under BSD-License. See LICENSE file in this repository.
- UZTextView uses [SECoreTextView](https://github.com/kishikawakatsumi/SECoreTextView) source code. [SECoreTextView](https://github.com/kishikawakatsumi/SECoreTextView) is available under the MIT license.	