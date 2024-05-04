//
//  WorkCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/3/24.
//

import UIKit
import MapKit
import FDTake

class WorkCell: UITableViewCell {
    
    static let identifier = "WorkCell"
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
    @IBOutlet weak var finalPlaceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var milesDrivenLabel: UILabel!
    
    @IBOutlet weak var ticketNumberTextField: UITextField!
    @IBOutlet weak var moneyTextField: UITextField!
    @IBOutlet weak var notesTextField: UITextField!
    
    @IBOutlet weak var cameraButton: UIButton!

    var work: Work!
    
    var image: UIImage?
    
    weak var parentVC: HomeVC!
    
    var camera: FDTakeController!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        containerView.layer.cornerRadius = 20
        topBarView.clipsToBounds = true
        topBarView.layer.cornerRadius = 20
        topBarView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Top right corner, Top left corner respectively
        containerView.dropShadow(radius: 5)
        
        ticketNumberTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        moneyTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        notesTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    func setup(with w: Work, fields: (String, Double?, String, UIImage?)?) {
        self.work = w
        
        let initTime = work.initialDate.toHourMinuteTime()
        let finalTime = work.finalDate.toHourMinuteTime()
        if initTime.hasSuffix(finalTime.suffix(2)) {
            self.timeLabel.text = "\(initTime.prefix(initTime.count - 3)) - \(finalTime)"
        }
        else {
            self.timeLabel.text = "\(initTime) - \(finalTime)"
        }
        
        self.finalPlaceLabel.textColor = .gray
        self.finalPlaceLabel.text = "Loading"
        self.milesDrivenLabel.textColor = .gray
        self.milesDrivenLabel.text = "Loading"
        
        self.dateLabel.text = "\(w.finalDate.get(.month))/\(w.finalDate.get(.day))"
        
        if w.finalPlace == nil {
            //TODO: ADD TO REVERSE GEOLOCATION QUEUE
        }
        else {
            self.finalPlaceLabel.text = w.finalPlace?.removeNumbers()
            self.finalPlaceLabel.textColor = .black
        }
        
//        getMilesBetween(work.initialCoordinate, and: drive.finalCoordinate) { miles in
//            DispatchQueue.main.async {
//                self.milesDrivenLabel.text = "\(String(format: "%.1f", miles)) mile drive"
//                self.milesDrivenLabel.textColor = .black
//            }
//        }
        if let place = w.finalPlace {
            self.milesDrivenLabel.text = "Work at \(place)"
        } else {
            self.milesDrivenLabel.text = "Work"
        }
        self.milesDrivenLabel.textColor = .black
        
        camera = FDTakeController()
        camera.allowsVideo = false
        
        if work.finalDate == Date.ongoingDate {
            if let place = w.finalPlace {
                self.milesDrivenLabel.text = "Ongoing work at \(place)"
            } else {
                self.milesDrivenLabel.text = "Ongoing work"
            }
            
            self.timeLabel.text = "\(initTime) - Now"
        }
        
        if work.finalDate == .ongoingDate {
            self.dateLabel.text = ""
        }
        
        if let fields = fields {
            self.ticketNumberTextField.text = fields.0
            if let money = fields.1 {
                self.moneyTextField.text = "\(money)"
            } else {
                self.moneyTextField.text = ""
            }
            self.notesTextField.text = fields.2
            if let image = fields.3 {
                self.image = image
            } else {
                self.image = nil
            }
            print((w.initialPlace ?? "place") + ": \(self.image)")
        } else {
            self.ticketNumberTextField.text = ""
            self.moneyTextField.text = ""
            self.notesTextField.text = ""
            self.image = nil
        }
        updateCameraButton()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func checkMarkClicked(_ sender: Any) {
        
        let ticketNumber = ticketNumberTextField.text ?? ""
        let money = moneyTextField.text == "" ? 0.00 : Double(moneyTextField.text ?? "0")
        let notes = notesTextField.text ?? ""
        
        let registeredWork = RegisteredWork(from: work, moneySpent: money ?? 0.00, ticketNumber: ticketNumber, notes: notes, image: image ?? UIImage.checkmark)
        
        
        if let image = image {
            NotificationCenter.default.post(name: .workMarkedAsRegistered, object: nil, userInfo: ["work" : self.work!, "registered_work" : registeredWork, "receipt_image" : image])
        } else {
            NotificationCenter.default.post(name: .workMarkedAsRegistered, object: nil, userInfo: ["work" : self.work!, "registered_work" : registeredWork])
        }
    }
    
    @IBAction func trashButtonClicked(_ sender: Any) {
        NotificationCenter.default.post(name: .workMarkedAsDeleted, object: nil, userInfo: ["work" : self.work!])
    }
    
    @IBAction func mapButtonClicked(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: DriveMapVC.identifier) as! DriveMapVC
        
        parentVC.present(vc, animated: true) {
            vc.setup(with: self.work)
        }
    }
    
    @IBAction func cameraButtonClicked(_ sender: Any) {
        camera.present()
        parentVC.isPresentingCamera = true
        camera.didGetPhoto = {
            (_ photo: UIImage, _ info: [AnyHashable : Any]) in
            
            
            self.image = photo
            self.updateCameraButton()
            self.textFieldDidChange()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.parentVC.isPresentingCamera = false
            }
        }
    }
    
    func updateCameraButton() {
        if self.image != nil {
            self.cameraButton.setImage(UIImage(systemName: "icloud.and.arrow.up"), for: .normal)
        } else {
            self.cameraButton.setImage(UIImage(systemName: "camera"), for: .normal)
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
