//
//  DropboxFolderConnectCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/12/24.
//

import UIKit

class DropboxFolderConnectCell: UITableViewCell {

    static let identifier = "DropboxFolderConnectCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setup(with folder: DropboxFolder) {
        nameLabel.text = folder.name
    }

}
