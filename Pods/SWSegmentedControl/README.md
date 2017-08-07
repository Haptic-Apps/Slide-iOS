# SWSegmentedControl

A Android-like tab bar, drop-in replacement for UISegmentedControl written in Swift.

![Live Demo](https://cloud.githubusercontent.com/assets/795368/12671575/2345a69a-c6a3-11e5-94f6-e8cd9e7c0be9.gif)

## Requirements

Requires iOS 8.0 and ARC.

## Installation

SWSegmentedControl is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SWSegmentedControl"
```

## Usage

SWSegmentedControl can only be init in code due to the limitation of @IBDesignable which can't generate array of item like what UISegmentedControl can do, but I make it renderable anyway just in case you want to play around with it.

### Basic usage

```
let sc = SWSegmentedControl(items: ["A", "B", "C"])
sc.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
sc.selectedSegmentIndex = 2 // default to 0
```

### Change segment programmatically

Setting property directly will change segment without animation

```
sc.selectedSegmentIndex = 1
```

If you want fine-grain control over animation, you can use `setSelectedSegmentIndex(index: Int, animated: Bool`

```
sc.setSelectedSegmentIndex(1, animated: true)
```

### Customization

By default both text and indicator color are the same with `tintColor`. If you want to change theme independently you can use `titleColor` and `indicatorColor` and you can also change font by set `font`.

## Author

Sarun Wongpatcharapakorn (artwork.th@gmail.com) Twitter: [@sarunw](https://twitter.com/sarunw)

## License

SWSegmentedControl is available under the MIT license. See the LICENSE file for more info.
