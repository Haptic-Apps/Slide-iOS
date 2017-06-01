//
//  MarginedTableViewCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 5/30/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class MarginedTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func getMargin() -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }

}
