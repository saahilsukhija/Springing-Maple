//
//  CombinedCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 10/14/24.
//

import UIKit
import FDTake

class CombinedCell: UITableViewCell {

    static let identifier = "CombinedCell"
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topBarView: UIView!
    

    @IBOutlet weak var driveInitialTimeLabel: UILabel!
    @IBOutlet weak var driveFinalTimeLabel: UILabel!
    @IBOutlet weak var workTimeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var driveInitialPlaceLabel: UILabel!
    @IBOutlet weak var driveFinalPlaceLabel: UILabel!
    @IBOutlet weak var workPlaceLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var ticketNumberTextField: UITextField!
    @IBOutlet weak var moneyTextField: UITextField!
    @IBOutlet weak var notesTextField: UITextField!
    
    @IBOutlet weak var receiptCameraButton: UIButton!
    @IBOutlet weak var propertyImagesCameraButton: UIButton!
    
    var work: Work!
    var drive: Drive!
    
    var image: UIImage?
    
    weak var parentVC: HomeVC!
    
    var camera: FDTakeController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 20
        topBarView.clipsToBounds = true
        topBarView.layer.cornerRadius = 20
        topBarView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Top right corner, Top left corner respectively
        containerView.dropShadow(radius: 5)
        
        ticketNumberTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        moneyTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        notesTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    func setup(with d: Drive, w: Work, fields: (String, Double?, String, UIImage?)?) {
        self.drive = d
        self.work = w
        
        self.driveInitialTimeLabel.text = d.initialDate.toHourMinuteTime()
        self.driveFinalTimeLabel.text = d.finalDate.toHourMinuteTime()
        let initTime = work.initialDate.toHourMinuteTime()
        let finalTime = work.finalDate.toHourMinuteTime()
        if initTime.hasSuffix(finalTime.suffix(2)) {
            self.workTimeLabel.text = "\(initTime.prefix(initTime.count - 3)) - \(finalTime)"
        }
        else {
            self.workTimeLabel.text = "\(initTime) - \(finalTime)"
        }
        
        self.driveInitialPlaceLabel.textColor = .gray
        self.driveInitialPlaceLabel.text = "Loading"
        self.driveFinalPlaceLabel.textColor = .gray
        self.driveFinalPlaceLabel.text = "Loading"
        self.workPlaceLabel.textColor = .gray
        self.workPlaceLabel.text = "Loading"
        
        self.titleLabel.textColor = .black
        
        if drive.finalPlace != nil {
            self.titleLabel.text = "\(drive.finalPlace!)"
        } else if work.initialPlace != nil {
            self.titleLabel.text = "\(work.initialPlace!)"
        } else {
            self.titleLabel.text = "Work at unknown location"
        }
        
        self.dateLabel.text = "\(d.finalDate.get(.month))/\(d.finalDate.get(.day))"
        
        if d.finalPlace == nil {
            //TODO: ADD TO REVERSE GEOLOCATION QUEUE
        }
        else {
            self.driveFinalPlaceLabel.text = d.finalPlace?.removeNumbers()
            self.driveFinalPlaceLabel.textColor = .black
        }
        
        if d.initialPlace == nil {
            LocationManager.geocode(coordinate: drive.initialCoordinate) { placemark, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self.drive.setInitPlace(placemark?[0].name ?? "(error)")
                }
                
                DispatchQueue.main.async {
                    self.driveInitialPlaceLabel.text = self.drive.initialPlace
                    self.driveInitialPlaceLabel.textColor = .black
                }
            }
        }
        else {
            self.driveInitialPlaceLabel.text = d.initialPlace?.removeNumbers()
            self.driveInitialPlaceLabel.textColor = .black
        }
        
        if let fields = fields {
            self.ticketNumberTextField.text = fields.0
            self.notesTextField.text = fields.2
        }
        else {
           self.ticketNumberTextField.text = ""
           self.notesTextField.text = ""
       }
        
        if drive.finalDate == .ongoingDate {
            self.titleLabel.text = "Pending"
            self.driveFinalPlaceLabel.text = "Pending"
            self.driveFinalPlaceLabel.textColor = .systemGray
            self.driveFinalTimeLabel.text = ""
            self.dateLabel.text = "\(d.initialDate.get(.month))/\(d.initialDate.get(.day))"
        }
        
    }
    
    @objc func textFieldDidChange() {
        
        if moneyTextField.text?.count ?? 0 > 0 {
            parentVC.userEnteredValues[work.initialDate] = (ticketNumberTextField.text ?? "", Double(moneyTextField.text ?? "0"), notesTextField.text ?? "", self.image)
        } else {
            parentVC.userEnteredValues[work.initialDate] = (ticketNumberTextField.text ?? "", nil, notesTextField.text ?? "", self.image)
        }
        
    }
    

}
