//
//  DriveMapVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/5/24.
//

import UIKit
import MapKit

class DriveMapVC: UIViewController {

    static let identifier = "DriveMapScreen"
    
    @IBOutlet weak var mapView: MKMapView!
    
    //@IBOutlet weak var centerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mapView.delegate = self
    }
    
    func setup(with drive: Drive) {
        let initialAnnotation = MKPointAnnotation()
        initialAnnotation.coordinate = drive.initialCoordinate
        initialAnnotation.title = "Start"
        mapView.addAnnotation(initialAnnotation)
        
        let endAnnotation = MKPointAnnotation()
        endAnnotation.coordinate = drive.finalCoordinate
        endAnnotation.title = "End"
        mapView.addAnnotation(endAnnotation)
        
        mapView.fitAll()
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
}

extension DriveMapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let title = annotation.title else { return nil }
        let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: title)
        if title == "Start" {
            view.markerTintColor = .mapGreen
        } else {
            view.markerTintColor = .mapRed
        }
    
        return view
        
        
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
       // centerButton.setImage(UIImage(systemName: "location"), for: .normal)
    }
}
