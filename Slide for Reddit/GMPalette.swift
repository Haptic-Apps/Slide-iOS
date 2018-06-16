//
//  GMPalette.swift
//  GMColor
//
//  Created by Todsaporn Banjerdkit (katopz) on 12/22/14.
//  Copyright (c) 2014 Debokeh. All rights reserved.
//

import UIKit

class GMPalette {

    static func all() -> [[UIColor]] {
        return [red(), pink(), purple(),
                deepPurple(), indigo(), blue(),
                lightBlue(), cyan(), teal(),
                green(), lightGreen(), lime(),
                yellow(), amber(), orange(),
                deepOrange(), brown(), grey(),
                blueGrey(), blackAndWhite()
        ]
    }

    static func allAccent() -> [[UIColor]] {
        return [redA(), pinkA(), purpleA(),
                deepPurpleA(), indigoA(), blueA(),
                lightBlueA(), cyanA(), tealA(),
                greenA(), lightGreenA(), limeA(),
                yellowA(), amberA(), orangeA(),
                deepOrangeA()]
    }

    static func toCGC(colors: [UIColor]) -> [CGColor] {
        var toReturn: [CGColor] = []
        var i = 0
        for color in colors {
            if (i < 3) {
                i += 1
            } else {
                toReturn.append(color.cgColor)
            }
        }
        return toReturn
    }

    static func allColor() -> [UIColor] {
        var toReturn: [UIColor] = []
        for i in all() {
            toReturn.append(contentsOf: i)
        }
        return toReturn
    }

    static func allColorAccent() -> [UIColor] {
        var toReturn: [UIColor] = []
        for i in allAccent() {
            toReturn.append(contentsOf: i)
        }
        return toReturn
    }

    static func allCGColor() -> [CGColor] {
        var toReturn: [CGColor] = []
        for a in all() {
            toReturn.append(contentsOf: toCGC(colors: a))
        }
        return toReturn
    }

    static func allAccentCGColor() -> [CGColor] {
        var toReturn: [CGColor] = []
        for a in allAccent() {
            toReturn.append(contentsOf: toCGC(colors: a))
        }
        return toReturn
    }

    class func red() -> [UIColor] {
        return [GMColor.red100Color(),
                GMColor.red200Color(), GMColor.red300Color(),
                GMColor.red400Color(), GMColor.red500Color(),
                GMColor.red600Color(), GMColor.red700Color(),
                GMColor.red800Color(), GMColor.red900Color()
        ]
    }

    class func redA() -> [UIColor] {
        return [GMColor.redA100Color(), GMColor.redA200Color(),
                GMColor.redA400Color(), GMColor.redA700Color()]
    }

    class func pink() -> [UIColor] {
        return [GMColor.pink100Color(),
                GMColor.pink200Color(), GMColor.pink300Color(),
                GMColor.pink400Color(), GMColor.pink500Color(),
                GMColor.pink600Color(), GMColor.pink700Color(),
                GMColor.pink800Color(), GMColor.pink900Color()
        ]
    }

    class func pinkA() -> [UIColor] {
        return [GMColor.pinkA100Color(), GMColor.pinkA200Color(),
                GMColor.pinkA400Color(), GMColor.pinkA700Color()]
    }

    class func purple() -> [UIColor] {
        return [GMColor.purple100Color(),
                GMColor.purple200Color(), GMColor.purple300Color(),
                GMColor.purple400Color(), GMColor.purple500Color(),
                GMColor.purple600Color(), GMColor.purple700Color(),
                GMColor.purple800Color(), GMColor.purple900Color()
        ]
    }

    class func purpleA() -> [UIColor] {
        return [GMColor.purpleA100Color(), GMColor.purpleA200Color(),
                GMColor.purpleA400Color(), GMColor.purpleA700Color()]
    }

    class func deepPurple() -> [UIColor] {
        return [GMColor.deepPurple100Color(),
                GMColor.deepPurple200Color(), GMColor.deepPurple300Color(),
                GMColor.deepPurple400Color(), GMColor.deepPurple500Color(),
                GMColor.deepPurple600Color(), GMColor.deepPurple700Color(),
                GMColor.deepPurple800Color(), GMColor.deepPurple900Color()
        ]
    }

    class func deepPurpleA() -> [UIColor] {
        return [GMColor.deepPurpleA100Color(), GMColor.deepPurpleA200Color(),
                GMColor.deepPurpleA400Color(), GMColor.deepPurpleA700Color()]
    }

    class func indigo() -> [UIColor] {
        return [GMColor.indigo100Color(),
                GMColor.indigo200Color(), GMColor.indigo300Color(),
                GMColor.indigo400Color(), GMColor.indigo500Color(),
                GMColor.indigo600Color(), GMColor.indigo700Color(),
                GMColor.indigo800Color(), GMColor.indigo900Color()
        ]
    }

    class func indigoA() -> [UIColor] {
        return [GMColor.indigoA100Color(), GMColor.indigoA200Color(),
                GMColor.indigoA400Color(), GMColor.indigoA700Color()]
    }

    class func blue() -> [UIColor] {
        return [GMColor.blue100Color(),
                GMColor.blue200Color(), GMColor.blue300Color(),
                GMColor.blue400Color(), GMColor.blue500Color(),
                GMColor.blue600Color(), GMColor.blue700Color(),
                GMColor.blue800Color(), GMColor.blue900Color()
        ]
    }

    class func blueA() -> [UIColor] {
        return [GMColor.blueA100Color(), GMColor.blueA200Color(),
                GMColor.blueA400Color(), GMColor.blueA700Color()]
    }

    class func lightBlue() -> [UIColor] {
        return [GMColor.lightBlue100Color(),
                GMColor.lightBlue200Color(), GMColor.lightBlue300Color(),
                GMColor.lightBlue400Color(), GMColor.lightBlue500Color(),
                GMColor.lightBlue600Color(), GMColor.lightBlue700Color(),
                GMColor.lightBlue800Color(), GMColor.lightBlue900Color()
        ]
    }

    class func lightBlueA() -> [UIColor] {
        return [GMColor.lightBlueA100Color(), GMColor.lightBlueA200Color(),
                GMColor.lightBlueA400Color(), GMColor.lightBlueA700Color()]
    }

    class func cyan() -> [UIColor] {
        return [GMColor.cyan100Color(),
                GMColor.cyan200Color(), GMColor.cyan300Color(),
                GMColor.cyan400Color(), GMColor.cyan500Color(),
                GMColor.cyan600Color(), GMColor.cyan700Color(),
                GMColor.cyan800Color(), GMColor.cyan900Color()
        ]
    }

    class func cyanA() -> [UIColor] {
        return [GMColor.cyanA100Color(), GMColor.cyanA200Color(),
                GMColor.cyanA400Color(), GMColor.cyanA700Color()]
    }

    class func teal() -> [UIColor] {
        return [GMColor.teal100Color(),
                GMColor.teal200Color(), GMColor.teal300Color(),
                GMColor.teal400Color(), GMColor.teal500Color(),
                GMColor.teal600Color(), GMColor.teal700Color(),
                GMColor.teal800Color(), GMColor.teal900Color()
        ]
    }

    class func tealA() -> [UIColor] {
        return [GMColor.tealA100Color(), GMColor.tealA200Color(),
                GMColor.tealA400Color(), GMColor.tealA700Color()]
    }

    class func green() -> [UIColor] {
        return [GMColor.green100Color(),
                GMColor.green200Color(), GMColor.green300Color(),
                GMColor.green400Color(), GMColor.green500Color(),
                GMColor.green600Color(), GMColor.green700Color(),
                GMColor.green800Color(), GMColor.green900Color()
        ]
    }

    class func greenA() -> [UIColor] {
        return [GMColor.greenA100Color(), GMColor.greenA200Color(),
                GMColor.greenA400Color(), GMColor.greenA700Color()]
    }

    class func lightGreen() -> [UIColor] {
        return [GMColor.lightGreen100Color(),
                GMColor.lightGreen200Color(), GMColor.lightGreen300Color(),
                GMColor.lightGreen400Color(), GMColor.lightGreen500Color(),
                GMColor.lightGreen600Color(), GMColor.lightGreen700Color(),
                GMColor.lightGreen800Color(), GMColor.lightGreen900Color()
        ]
    }

    class func lightGreenA() -> [UIColor] {
        return [GMColor.lightGreenA100Color(), GMColor.lightGreenA200Color(),
                GMColor.lightGreenA400Color(), GMColor.lightGreenA700Color()]
    }

    class func lime() -> [UIColor] {
        return [GMColor.lime100Color(),
                GMColor.lime200Color(), GMColor.lime300Color(),
                GMColor.lime400Color(), GMColor.lime500Color(),
                GMColor.lime600Color(), GMColor.lime700Color(),
                GMColor.lime800Color(), GMColor.lime900Color()
        ]
    }

    class func limeA() -> [UIColor] {
        return [GMColor.limeA100Color(), GMColor.limeA200Color(),
                GMColor.limeA400Color(), GMColor.limeA700Color()]
    }

    class func yellow() -> [UIColor] {
        return [GMColor.yellow100Color(),
                GMColor.yellow200Color(), GMColor.yellow300Color(),
                GMColor.yellow400Color(), GMColor.yellow500Color(),
                GMColor.yellow600Color(), GMColor.yellow700Color(),
                GMColor.yellow800Color(), GMColor.yellow900Color()
        ]
    }

    class func yellowA() -> [UIColor] {
        return [GMColor.yellowA100Color(), GMColor.yellowA200Color(),
                GMColor.yellowA400Color(), GMColor.yellowA700Color()]
    }

    class func amber() -> [UIColor] {
        return [GMColor.amber100Color(),
                GMColor.amber200Color(), GMColor.amber300Color(),
                GMColor.amber400Color(), GMColor.amber500Color(),
                GMColor.amber600Color(), GMColor.amber700Color(),
                GMColor.amber800Color(), GMColor.amber900Color()
        ]
    }

    class func amberA() -> [UIColor] {
        return [GMColor.amberA100Color(), GMColor.amberA200Color(),
                GMColor.amberA400Color(), GMColor.amberA700Color()]
    }

    class func orange() -> [UIColor] {
        return [GMColor.orange100Color(),
                GMColor.orange200Color(), GMColor.orange300Color(),
                GMColor.orange400Color(), GMColor.orange500Color(),
                GMColor.orange600Color(), GMColor.orange700Color(),
                GMColor.orange800Color(), GMColor.orange900Color()
        ]
    }

    class func orangeA() -> [UIColor] {
        return [GMColor.orangeA100Color(), GMColor.orangeA200Color(),
                GMColor.orangeA400Color(), GMColor.orangeA700Color()]
    }

    class func deepOrange() -> [UIColor] {
        return [GMColor.deepOrange100Color(),
                GMColor.deepOrange200Color(), GMColor.deepOrange300Color(),
                GMColor.deepOrange400Color(), GMColor.deepOrange500Color(),
                GMColor.deepOrange600Color(), GMColor.deepOrange700Color(),
                GMColor.deepOrange800Color(), GMColor.deepOrange900Color()
        ]
    }

    class func deepOrangeA() -> [UIColor] {
        return [GMColor.deepOrangeA100Color(), GMColor.deepOrangeA200Color(),
                GMColor.deepOrangeA400Color(), GMColor.deepOrangeA700Color()]
    }

    class func brown() -> [UIColor] {
        return [GMColor.brown100Color(),
                GMColor.brown200Color(), GMColor.brown300Color(),
                GMColor.brown400Color(), GMColor.brown500Color(),
                GMColor.brown600Color(), GMColor.brown700Color(),
                GMColor.brown800Color(), GMColor.brown900Color()
        ]
    }

    class func grey() -> [UIColor] {
        return [GMColor.grey100Color(),
                GMColor.grey200Color(), GMColor.grey300Color(),
                GMColor.grey400Color(), GMColor.grey500Color(),
                GMColor.grey600Color(), GMColor.grey700Color(),
                GMColor.grey800Color(), GMColor.grey900Color()
        ]
    }

    class func blueGrey() -> [UIColor] {
        return [GMColor.blueGrey100Color(),
                GMColor.blueGrey200Color(), GMColor.blueGrey300Color(),
                GMColor.blueGrey400Color(), GMColor.blueGrey500Color(),
                GMColor.blueGrey600Color(), GMColor.blueGrey700Color(),
                GMColor.blueGrey800Color(), GMColor.blueGrey900Color()
        ]
    }

    class func blackAndWhite() -> [UIColor] {
        return [GMColor.blackColor()]
    }
}
