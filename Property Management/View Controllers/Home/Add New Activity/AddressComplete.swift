//
//  AddressComplete.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/24/24.
//

import UIKit
import CoreLocation
import MapKit

protocol MapDataSourceDelegate: AnyObject {
    func refreshData()
    func didSelectAddress(_ address: String, location: CLLocationCoordinate2D)
}

class MapDataSource: NSObject {
    
    private var search: MKLocalSearch? = nil
    private var searchCompleter = MKLocalSearchCompleter()
    private var places = [MKLocalSearchCompletion]()
    private var savedLocationMatches: [(String, String)] = [] // Store matches from saved locations

    weak var delegate: MapDataSourceDelegate?

    override init() {
        super.init()
        searchCompleter.delegate = self
        
        savedLocationMatches = SavedLocations.shared.locations.compactMap { location in
            return (location.actualName, location.assignedName)
        }
    }
    
    // Query saved locations and update matches
    func searchSavedLocationsFor(_ text: String) {
        savedLocationMatches = SavedLocations.shared.locations.compactMap { location in
            if location.actualName.lowercased().contains(text.lowercased()) ||
                location.assignedName.lowercased().contains(text.lowercased()) {
                return (location.actualName, location.assignedName)
            }
            return nil
        }
        
        if savedLocationMatches.count == 0 && text == "" {
            savedLocationMatches = SavedLocations.shared.locations.compactMap { location in
                return (location.actualName, location.assignedName)
            }
        }
        
        // Notify the delegate of updated saved location matches
        //delegate?.didUpdateSavedLocations(savedLocationMatches)
    }
    
    func locationCount() -> Int {
        return places.count
    }
    
    func locationAt(index: IndexPath) -> MKLocalSearchCompletion {
        return places[index.row]
    }
    
    func savedLocationCount() -> Int {
        return savedLocationMatches.count
    }
    
    func savedLocationAt(index: IndexPath) -> (String, String) {
        guard index.row < savedLocationMatches.count else { return ("", "") }
        return savedLocationMatches[index.row]
    }
}

extension MapDataSource: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
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
        guard let location = locations.first else { return }
        searchCompleter.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 150, longitudinalMeters: 150)
    }
}

extension MapDataSource: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // One for saved locations, one for search results
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return savedLocationCount() // Number of saved location matches
        } else {
            return locationCount() // Number of search results
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddressLookupCell.identifier, for: indexPath) as! AddressLookupCell
        
        if indexPath.section == 0 {
            // Configure cell for saved locations
            let item = savedLocationAt(index: indexPath)
            cell.placeLabel?.text = item.1
            cell.subtitleLabel?.text = item.0
        } else {
            // Configure cell for search results
            let item = locationAt(index: indexPath)
            if let index = item.subtitle.firstIndex(of: ",") {
                cell.placeLabel?.text = item.title + ", " + item.subtitle[..<index]
            } else {
                cell.placeLabel?.text = item.title
            }
            cell.subtitleLabel?.text = ""
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let arr = ["Saved locations", "Search results"]
        return arr[section]
    }
}

extension MapDataSource: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            // Handle selection of saved locations
            let item = savedLocationAt(index: indexPath)
            delegate?.didSelectAddress(item.1, location: CLLocationCoordinate2D()) // Update with actual location if needed
        } else {
            // Handle selection of search results
            let item = locationAt(index: indexPath)
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = item.subtitle
            let search = MKLocalSearch(request: request)
            search.start { (response, error) in
                guard let response = response, let item = response.mapItems.first else { return }
                self.delegate?.didSelectAddress((tableView.cellForRow(at: indexPath) as! AddressLookupCell).placeLabel.text ?? "", location: item.placemark.coordinate)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MapDataSource: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        places = completer.results
        delegate?.refreshData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
}

extension MapDataSource {
    func updateQuery(with text: String) {
        searchSavedLocationsFor(text) // Search saved locations as well
        searchCompleter.queryFragment = text

    }
}
