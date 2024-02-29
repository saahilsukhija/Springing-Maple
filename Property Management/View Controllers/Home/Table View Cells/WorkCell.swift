//
//  DriveCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/3/24.
//

import UIKit
import MapKit
import FDTake

class DriveCell: UITableViewCell {
    
    static let identifer = "WorkCell"
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var initialPlaceLabel: UILabel!
    @IBOutlet weak var initialTimeLabel: UILabel!
    @IBOutlet weak var finalPlaceLabel: UILabel!
    @IBOutlet weak var finalTimeLabel: UILabel!
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
        containerView.dropShadow(radius: 8)
    }
    
    func setup(with w: work) {
        self.work = w
        
        self.initialTimeLabel.text = drive.initialDate.toHourMinuteTime()
        self.finalTimeLabel.text = drive.finalDate.toHourMinuteTime()
        
        self.initialPlaceLabel.textColor = .gray
        self.initialPlaceLabel.text = "Loading"
        self.finalPlaceLabel.textColor = .gray
        self.finalPlaceLabel.text = "Loading"
        self.milesDrivenLabel.textColor = .gray
        self.milesDrivenLabel.text = "Loading"
        
        self.dateLabel.text = "\(d.finalDate.get(.month))/\(d.finalDate.get(.day))"
        
        if d.initialPlace == nil {
            //TODO: ADD TO REVERSE GEOLOCATION QUEUE
        } else {
            self.initialPlaceLabel.text = d.initialPlace
            self.initialPlaceLabel.textColor = .black
        }
        if d.finalPlace == nil {
            //TODO: ADD TO REVERSE GEOLOCATION QUEUE
        }
        else {
            self.finalPlaceLabel.text = d.finalPlace
            self.finalPlaceLabel.textColor = .black
        }
        
        getMilesBetween(drive.initialCoordinate, and: drive.finalCoordinate) { miles in
            DispatchQueue.main.async {
                self.milesDrivenLabel.text = "\(String(format: "%.1f", miles)) mile drive"
                self.milesDrivenLabel.textColor = .black
            }
        }
        
        camera = FDTakeController()
        camera.allowsVideo = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func checkMarkClicked(_ sender: Any) {
        
        let ticketNumber = ticketNumberTextField.text ?? ""
        let money = moneyTextField.text == "" ? 0.00 : Double(moneyTextField.text ?? "0")
        let notes = notesTextField.text ?? ""
        
        let registeredDrive = RegisteredWork(from: drive, moneySpent: money ?? 0.00, ticketNumber: ticketNumber, notes: notes, image: image ?? UIImage.checkmark)
        registeredDrive.setInitialGeocodedLocation(initialPlaceLabel.text ?? "")
        registeredDrive.setFinalGeocodedLocation(finalPlaceLabel.text ?? "")
        
        if let image = image {
            NotificationCenter.default.post(name: .driveMarkedAsRegistered, object: nil, userInfo: ["drive" : self.drive!, "registered_drive" : registeredDrive, "receipt_image" : image])
        } else {
            NotificationCenter.default.post(name: .driveMarkedAsRegistered, object: nil, userInfo: ["drive" : self.drive!, "registered_drive" : registeredDrive])
        }
    }
    
    @IBAction func trashButtonClicked(_ sender: Any) {
        NotificationCenter.default.post(name: .driveMarkedAsDeleted, object: nil, userInfo: ["drive" : self.drive!])
    }
    
    @IBAction func mapButtonClicked(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: DriveMapVC.identifier) as! DriveMapVC

        parentVC.present(vc, animated: true) {
            vc.setup(with: self.drive)
        }
    }
    
    @IBAction func cameraButtonClicked(_ sender: Any) {
        camera.present()
        parentVC.isPresentingCamera = true
        camera.didGetPhoto = {
            (_ photo: UIImage, _ info: [AnyHashable : Any]) in
            
            self.cameraButton.setImage(UIImage(systemName: "icloud.and.arrow.up"), for: .normal)
            self.image = photo
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.parentVC.isPresentingCamera = false
            }
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
        request.requestsAlternateRoutes = true

        let directions = MKDirections(request: request)

         // Now we have the routes, we can calculate the distance using
         directions.calculate { (response, error) in
            if let response = response, let route = response.routes.first {
                completion(route.distance/1609.34)
            }
         }
    }
}

extension DriveCell: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "\(drive.initialCoordinate.latitude) to \(drive.initialCoordinate.longitude)")
        return view
    }
}
