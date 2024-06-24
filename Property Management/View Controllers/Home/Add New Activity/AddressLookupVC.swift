//
//  AddressLookupVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 4/5/24.
//

import UIKit
import MapKit

class AddressLookupVC: UIViewController {
    
    static let identifier = "AddressLookupScreen"
    weak var delegate: AddressLookupDelegate?
     
    let dataSource = MapDataSource()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addressTextField: UITextField!
    
    private var addresses: [(String, String)] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        dataSource.delegate = self
        
        addressTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        tableView.delegate = dataSource
        tableView.dataSource = dataSource
        
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addressTextField.becomeFirstResponder()
    }
    
    @objc func textFieldChanged() {
        if addressTextField.text?.count ?? 0 > 0 {
            
//            completer.region = MKCoordinateRegion(center: LocationManager.shared.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), latitudinalMeters: 10_000, longitudinalMeters: 10_000)
//            completer.queryFragment = addressTextField.text!
            dataSource.updateQuery(with: addressTextField.text!)
        }
        else {
            addresses = []
            tableView.reloadData()
        }
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

//extension AddressLookupVC: UITableViewDelegate, UITableViewDataSource {
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: AddressLookupCell.identifier) as! AddressLookupCell
//        cell.setup(with: addresses[indexPath.row])
//        
//        //Separator Full Line
//        cell.preservesSuperviewLayoutMargins = false
//        cell.separatorInset = .zero
//        cell.layoutMargins = .zero
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return addresses.count
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let address = addresses[indexPath.row]
////        let completion = completer.results.first { com in
////
////        }
////        let search = MKLocalSearch(request: MKLocalSearch.Request(completion: completer.results))
//        delegate?.didChooseAddress(address)
//        tableView.deselectRow(at: indexPath, animated: true)
//        
//        navigationController?.popViewController(animated: true)
//    }
//    
//    
//    
//}

extension AddressLookupVC: MapDataSourceDelegate {
    func didSelectAddress(_ address: String, location: CLLocationCoordinate2D) {
        delegate?.didChooseAddress(address, coordinate: location)
        self.navigationController?.popViewController(animated: true)
    }
    
    func refreshData() {
        //self.addresses = addresses
        tableView.reloadData()
    }
}


protocol AddressLookupDelegate: AnyObject {
    
    func didChooseAddress(_ address: String, coordinate: CLLocationCoordinate2D)
}
