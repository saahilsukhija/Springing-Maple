//
//  AddressComplete.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/24/24.
//

import UIKit
import CoreLocation

import UIKit
import MapKit

protocol MapDataSourceDelegate: AnyObject {
    
    func refreshData()
    func didSelectAddress(_ address: String, location: CLLocationCoordinate2D)
    
}


class MapDataSource:NSObject{
    
    private var search:MKLocalSearch? =  nil
    
    
    private var searchCompleter = MKLocalSearchCompleter()
    
    private var places = [MKLocalSearchCompletion]()
    
    weak var delegate:MapDataSourceDelegate?
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        
    }
    
    func locationCount() -> Int {
        return places.count
    }
    
    func locationAt(index:IndexPath) -> MKLocalSearchCompletion{
        
        return places[index.row]
        
    }
    
    
    
    
    
}

extension MapDataSource:CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch  status {
        case .authorizedAlways, .authorizedWhenInUse:
            
            manager.requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else {return}
        
        searchCompleter.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 150, longitudinalMeters: 150)
        
        
    }
    
}

extension MapDataSource:UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let count = locationCount()
        
        return count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddressLookupCell.identifier, for: indexPath) as! AddressLookupCell
        
        // Configure the cell...
        let item = locationAt(index: indexPath)
        
        
        if let index = item.subtitle.index(of: ",") {
            cell.placeLabel?.text = item.title + ", " + item.subtitle.substring(with: Range(uncheckedBounds: (0,index)))
                    } else {
                        cell.placeLabel?.text = item.title
                    }
//        cell.placeLabel?.text = item.title
//        
        cell.subtitleLabel?.text = ""
        
        return cell
    }
    
}

extension MapDataSource:UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = locationAt(index: indexPath)
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = item.subtitle
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            
            guard let response = response else {return}
            guard let item = response.mapItems.first else {return}
            
            self.delegate?.didSelectAddress((tableView.cellForRow(at: indexPath) as! AddressLookupCell).placeLabel.text ?? "", location: item.placemark.coordinate)
        }
    }
}


extension MapDataSource:MKLocalSearchCompleterDelegate{
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        places = completer.results
        
        delegate?.refreshData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        
        
    }
}


extension MapDataSource {
    
    func updateQuery(with text: String) {
        searchCompleter.queryFragment = text
        
    }
}
