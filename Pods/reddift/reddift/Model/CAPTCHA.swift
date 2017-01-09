//
//  CAPTCHA.swift
//  reddift
//
//  Created by sonson on 2015/05/29.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
CAPTCHA data class.
*/
public struct CAPTCHA {
    public let iden: String
    public let image: CAPTCHAImage
    
    init(iden: String, image: CAPTCHAImage) {
        self.iden = iden
        self.image = image
    }
}
