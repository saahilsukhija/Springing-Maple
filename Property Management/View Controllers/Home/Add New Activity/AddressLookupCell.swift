//
//  AddressLookupCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 4/5/24.
//

import UIKit

class AddressLookupCell: UITableViewCell {

    static let identifier = "AddressLookupCell"
    
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    func setup(with address: (String, String)) {
        placeLabel.text = address.0
        subtitleLabel.text = address.1
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
