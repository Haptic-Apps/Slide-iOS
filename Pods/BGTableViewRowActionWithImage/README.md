# BGTableViewRowActionWithImage

A variation on the iOS 8.0+ `UITableViewRowAction` to support icons, with text below. Similar to the iOS 9 Mail application and various third-party applications. We're all secretly hoping that Apple will implement this functionality with a native, public API in a future iOS update.

**This current implementation isn't ideal,** but it works. Until it becomes a built-in property for `UITableViewRowAction`, please feel free to contribute any improvements or compatibility tweaks as you see fit.

[![Version](https://img.shields.io/cocoapods/v/BGTableViewRowActionWithImage.svg?style=flat)](http://cocoapods.org/pods/BGTableViewRowActionWithImage)
[![License](https://img.shields.io/cocoapods/l/BGTableViewRowActionWithImage.svg?style=flat)](http://cocoapods.org/pods/BGTableViewRowActionWithImage)
[![Platform](https://img.shields.io/cocoapods/p/BGTableViewRowActionWithImage.svg?style=flat)](http://cocoapods.org/pods/BGTableViewRowActionWithImage)

### Some other helpful Cocoa Pods:
- **`BGPersistentStoreManager`** ([link](https://github.com/benguild/BGPersistentStoreManager)) — A simple singleton/wrapper/manager for the Apple iOS/macOS/etc. "Core Data" `NSPersistentStore` object/contexts.
- **`BGRecursiveTableViewDataSource`** ([link](https://github.com/benguild/BGRecursiveTableViewDataSource)) — Recursive “stacking” and modularization of `UITableViewDataSource(s)` with Apple iOS's UIKit.

## Objective-C Usage

```objc
// Regular width
+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style
                             title:(NSString *)title
                   backgroundColor:(UIColor *)backgroundColor
                             image:(UIImage *)image
                     forCellHeight:(NSUInteger)cellHeight
                           handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler;

+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style
                             title:(NSString *)title
                        titleColor:(UIColor *)titleColor
                   backgroundColor:(UIColor *)backgroundColor
                             image:(UIImage *)image
                     forCellHeight:(NSUInteger)cellHeight
                           handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler;

// Optional fitted width (ideal when using 3 or more cells in smaller tables)
+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style
                             title:(NSString *)title
                   backgroundColor:(UIColor *)backgroundColor
                             image:(UIImage *)image
                     forCellHeight:(NSUInteger)cellHeight
                    andFittedWidth:(BOOL)isWidthFitted
                           handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler;

+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style
                             title:(NSString *)title
                        titleColor:(UIColor *)titleColor
                   backgroundColor:(UIColor *)backgroundColor
                             image:(UIImage *)image
                     forCellHeight:(NSUInteger)cellHeight
                    andFittedWidth:(BOOL)isWidthFitted
                           handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler;
```

Use **one** of these constructors **only** to configure each row action, depending on your needs. Manually setting the `backgroundColor` property of a row action after calling a constructor will probably result in unexpected behavior, and should be avoided.

## Swift

For **Swift**, the syntax changes slightly:

```swift
// In your imports:
import BGTableViewRowActionWithImage

// In your code:
BGTableViewRowActionWithImage.rowActionWithStyle(/* see above for parameters... */)
```

See *"Objective-C Usage"* above for parameter configurations and **other important notes**.

## Demo

![Example screenshot](https://raw.github.com/benguild/BGTableViewRowActionWithImage/master/demo.jpg "Example screenshot")

## Installation

`BGTableViewRowActionWithImage` is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "BGTableViewRowActionWithImage"
```

## Author

Ben Guild, email@benguild.com

## License

`BGTableViewRowActionWithImage` is available under the MIT license. See the LICENSE file for more info.
