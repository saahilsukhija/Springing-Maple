//
//  NoActivityCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/17/24.
//

import UIKit

class NoActivityCell: UITableViewCell {

    static let identifier = "NoActivityCell"
    
    @IBOutlet weak var informationLabel: UILabel!
    
    var parentVC: HomeVC!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setup(vc: HomeVC) {
        
        self.parentVC = vc
        
        let text = "You have marked all your activities as complete. Add a new one, or wait for one to get automatically logged."
        informationLabel.text = text
        informationLabel.textColor =  UIColor.black
        informationLabel.font = UIFont(name: "Montserrat-Medium", size: 16)!
        let underlineAttriString = NSMutableAttributedString(string: text)
        let range1 = (text as NSString).range(of: "Add a new one")
             underlineAttriString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "Montserrat-Medium", size: 16)!, range: range1)
        underlineAttriString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.accentColor, range: range1)
        informationLabel.attributedText = underlineAttriString
        informationLabel.isUserInteractionEnabled = true
        informationLabel.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(labelTapped(_:))))

    }
    
    @objc func labelTapped(_ gesture: UITapGestureRecognizer) {
        parentVC.presentAddActivityVC()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
