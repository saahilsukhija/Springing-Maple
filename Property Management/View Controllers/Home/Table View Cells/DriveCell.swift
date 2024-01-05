//
//  VisitCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/3/24.
//

import UIKit
import MapKit

class VisitCell: UITableViewCell {
    
    static let identifer = "VisitCell"
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var mapview: MKMapView!
    
    var visit: Visit!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        containerView.layer.cornerRadius = 20
        containerView.dropShadow(radius: 8)
    }

    func setup(with v: Visit) {
        self.visit = v
        timeLabel.text = visit.arrivalDate.toHourMinuteTime()
        placeLabel.text = "Loading"
        placeLabel.textColor = .systemGray
        
        mapview.region = MKCoordinateRegion(center: visit.coordinate, span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))
        let annotation = MKPointAnnotation()
        annotation.coordinate = visit.coordinate
        mapview.addAnnotation(annotation)
        mapview.isZoomEnabled = false
        mapview.isPitchEnabled = false
        mapview.isRotateEnabled = false
        mapview.isScrollEnabled = false

        LocationManager.shared.getReverseGeoCodedLocation(location: CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)) { location, placemark, error in
            var text = ""
            if let error = error {
                text = "(error)"
                print(error.localizedDescription)
            } else {
                text = placemark?.name ?? "(error 2)"
            }
            
            DispatchQueue.main.async {
                self.placeLabel.text = text
                self.placeLabel.textColor = .black
            }
        }
        
       // placeLabel.text = visit.
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

extension VisitCell: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "\(visit.coordinate.latitude) to \(visit.coordinate.longitude)")
        return view
    }
}
