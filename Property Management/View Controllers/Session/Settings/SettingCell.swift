//
//  SettingCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/28/24.
//

import UIKit

class SettingCell: UITableViewCell {

    static let identifier = "SettingCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(title: String, status: String) {
        titleLabel.text = title
        statusLabel.text = status
        statusLabel.textColor = .systemGray
    }

}
