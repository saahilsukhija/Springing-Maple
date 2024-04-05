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
    private var completer: MKLocalSearchCompleter!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addressTextField: UITextField!
    
    private var addresses: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        completer = MKLocalSearchCompleter()
        completer.delegate = self
        
        addressTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addressTextField.becomeFirstResponder()
    }
    
    @objc func textFieldChanged() {
        if addressTextField.text?.count ?? 0 > 0 {
            completer.region = MKCoordinateRegion(center: LocationManager.shared.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0), latitudinalMeters: 10_000, longitudinalMeters: 10_000)
            completer.queryFragment = addressTextField.text!
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

extension AddressLookupVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddressLookupCell.identifier) as! AddressLookupCell
        cell.setup(with: addresses[indexPath.row])
        
        //Separator Full Line
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addresses.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = addresses[indexPath.row]
        
        delegate?.didChooseAddress(address)
        tableView.deselectRow(at: indexPath, animated: true)
        
        navigationController?.popViewController(animated: true)
    }
    
    
    
}

extension AddressLookupVC: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let addresses = completer.results.map { result in
            if let index = result.subtitle.index(of: ",") {
                result.title + ", " + result.subtitle.substring(with: Range(uncheckedBounds: (0,index)))
            } else {
                result.title
            }
        }
        
        self.addresses = addresses
        tableView.reloadData()
    }
}


protocol AddressLookupDelegate: AnyObject {
    
    func didChooseAddress(_ address: String)
}
