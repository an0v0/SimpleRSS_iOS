//
//  RSSTableViewCell.swift
//  SimpleRSS
//
//  Copyright © 2018年 an. All rights reserved.
//

import UIKit

class RSSTableViewCell: UITableViewCell {
    
    static let identifier = "RSSTableViewCell"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
