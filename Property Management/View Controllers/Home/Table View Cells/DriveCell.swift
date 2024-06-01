//
//  DriveCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 2/28/24.
//

import UIKit
import MapKit

class DriveCell: UITableViewCell {
    
    static let identifier = "DriveCell"
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topBarView: UIView!
    
    @IBOutlet weak var initialPlaceLabel: UILabel!
    @IBOutlet weak var finalPlaceLabel: UILabel!
    @IBOutlet weak var initialTimeLabel: UILabel!
    @IBOutlet weak var finalTimeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var milesDrivenLabel: UILabel!
    
    @IBOutlet weak var ticketNumberTextField: UITextField!
    @IBOutlet weak var notesTextField: UITextField!

    var drive: Drive!
    
    weak var parentVC: HomeVC!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        containerView.layer.cornerRadius = 20
        topBarView.clipsToBounds = true
        topBarView.layer.cornerRadius = 20
        topBarView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // Top right corner, Top left corner respectively
        containerView.dropShadow(radius: 5)
        
        ticketNumberTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        notesTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    func setup(with d: Drive, fields: (String, Double?, String, UIImage?)?) {
        self.drive = d
        
        self.initialTimeLabel.text = d.initialDate.toHourMinuteTime()
        self.finalTimeLabel.text = d.finalDate.toHourMinuteTime()
        
        self.finalPlaceLabel.textColor = .gray
        self.finalPlaceLabel.text = "Loading"
        self.milesDrivenLabel.textColor = .black
        if drive.finalPlace != nil {
            self.milesDrivenLabel.text = "Drive to \(drive.finalPlace!)"
        } else {
            self.milesDrivenLabel.text = "Drive"
        }
        
        self.dateLabel.text = "\(d.finalDate.get(.month))/\(d.finalDate.get(.day))"
        
        if d.finalPlace == nil {
            //TODO: ADD TO REVERSE GEOLOCATION QUEUE
        }
        else {
            self.finalPlaceLabel.text = d.finalPlace?.removeNumbers()
            self.finalPlaceLabel.textColor = .black
        }
        
        if d.initialPlace == nil {
            LocationManager.geocode(coordinate: drive.initialCoordinate) { placemark, error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self.drive.setInitPlace(placemark?[0].name ?? "(error)")
                }
                
                DispatchQueue.main.async {
                    self.initialPlaceLabel.text = self.drive.initialPlace
                    self.initialPlaceLabel.textColor = .black
                }
            }
        }
        else {
            self.initialPlaceLabel.text = d.initialPlace?.removeNumbers()
            self.initialPlaceLabel.textColor = .black
        }
        
        if drive.milesDriven == nil || drive.milesDriven == -1 {
            DispatchQueue.main.async {
                self.getMilesBetween(self.drive.initialCoordinate, and: self.drive.finalCoordinate) { miles in
                    DispatchQueue.main.async {
                        if miles != 0 {
                            self.milesDrivenLabel.text = "\(String(format: "%.1f", miles)) mile drive"
                            self.milesDrivenLabel.textColor = .black
                            self.drive.milesDriven = miles
                        }
                    }
                }
            }
        } else {
            self.milesDrivenLabel.text = "\(String(format: "%.1f", drive.milesDriven!)) mile drive"
            self.milesDrivenLabel.textColor = .black
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
            self.milesDrivenLabel.text = "Pending drive"
            self.finalPlaceLabel.text = "Pending"
            self.finalPlaceLabel.textColor = .systemGray
            self.finalTimeLabel.text = ""
            self.dateLabel.text = "\(d.initialDate.get(.month))/\(d.initialDate.get(.day))"
        }
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func checkMarkClicked(_ sender: Any) {
        if drive.finalDate == .ongoingDate {
            Alert.showDefaultAlert(title: "Unable to submit pending drive", message: "You are unable to submit a pending drive. Please wait until the drive is logged before submitting it", parentVC)
            return
        }
        
        let ticketNumber = ticketNumberTextField.text ?? ""
        let notes = notesTextField.text ?? ""
        
        let registeredDrive = RegisteredDrive(from: drive, ticketNumber: ticketNumber, notes: notes)
        

        NotificationCenter.default.post(name: .driveMarkedAsRegistered, object: nil, userInfo: ["drive" : self.drive!, "registered_drive" : registeredDrive])
    }
    
    @IBAction func trashButtonClicked(_ sender: Any) {
        if drive.finalDate == .ongoingDate {
            Alert.showDefaultAlert(title: "Unable to delete pending drive", message: "You are unable to delete a pending drive. Please wait until the drive is logged before deleting it", parentVC)
            return
        }
        NotificationCenter.default.post(name: .driveMarkedAsDeleted, object: nil, userInfo: ["drive" : self.drive!])
    }
    
    @IBAction func mapButtonClicked(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: DriveMapVC.identifier) as! DriveMapVC
        
        parentVC.present(vc, animated: true) {
            vc.setup(with: self.drive)
        }
    }
    
    func getMilesBetween(_ sourceP: CLLocationCoordinate2D, and destP: CLLocationCoordinate2D, completion: @escaping((Double) -> Void)) {
        let source = MKPlacemark(coordinate: sourceP)
        let destination = MKPlacemark(coordinate: destP)
                
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: source)
        request.destination = MKMapItem(placemark: destination)

        // Specify the transportation type
        request.transportType = MKDirectionsTransportType.automobile;

        // If you want only the shortest route, set this to a false
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

         // Now we have the routes, we can calculate the distance using
         directions.calculate { (response, error) in
            if let response = response, let route = response.routes.first {
                completion(route.distance/1609.34)
            }
             else {
                 completion(0)
                 print(error!)
             }
         }
    }
    
    @objc func textFieldDidChange() {
        

        parentVC.userEnteredValues[drive.initialDate] = (ticketNumberTextField.text ?? "", nil, notesTextField.text ?? "", nil)
        
    }
}

//extension DriveCell: MKMapViewDelegate {
//
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "\(drive.initialCoordinate.latitude) to \(drive.initialCoordinate.longitude)")
//        return view
//    }
//}
