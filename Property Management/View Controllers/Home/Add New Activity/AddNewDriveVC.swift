//
//  AddNewDriveVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/9/24.
//

import UIKit
import CoreLocation
class AddNewDriveVC: UIViewController {
    
    static let identifier = "AddNewDriveScreen"
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var initialTimePicker: UIDatePicker!
    @IBOutlet weak var finalTimePicker: UIDatePicker!
    
    @IBOutlet weak var initialPlaceField: UITextField!
    var initialPlaceCoordinate: CLLocationCoordinate2D?
    @IBOutlet weak var finalPlaceField: UITextField!
    var finalPlaceCoordinate: CLLocationCoordinate2D?
    @IBOutlet weak var ticketNumberField: UITextField!
    @IBOutlet weak var notesField: UITextField!
    
    var createButton: UIBarButtonItem!
    
    var currentTextField: Int! = -1 //0 for initial, 1 for final.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        //navigationController!.title = "Create Drive"
        
        createButton = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(createButtonClicked))
        createButton.tintColor = .systemGray
        self.navigationItem.rightBarButtonItems = [createButton]
        
        initialPlaceField.tag = 0
        initialPlaceField.delegate = self
        
        finalPlaceField.tag = 1
        finalPlaceField.delegate = self
        
        ticketNumberField.tag = 2
        ticketNumberField.delegate = self
        
        notesField.tag = 3
        notesField.delegate = self
        notesField.returnKeyType = .done
        
        initialPlaceField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(initialFieldClicked)))
        finalPlaceField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(finalFieldClicked)))
        
        self.hideKeyboardWhenTappedAround()
    }
    
    @objc func initialFieldClicked() {
        let vc = storyboard?.instantiateViewController(withIdentifier: AddressLookupVC.identifier) as! AddressLookupVC
        self.currentTextField = 0
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func finalFieldClicked() {
        let vc = storyboard?.instantiateViewController(withIdentifier: AddressLookupVC.identifier) as! AddressLookupVC
        self.currentTextField = 1
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
        
        
    }
    @objc func createButtonClicked() {
        guard initialPlaceField.text != "" else {
            self.showFailureToast(message: "Must give an initial address")
            return
        }
        
        guard finalPlaceField.text != "" else {
            self.showFailureToast(message: "Must give a final address")
            return
        }
        
        if ticketNumberField.text == "" {
            let alert = UIAlertController(title: "No Ticket Number Given!", message: "No ticket number was provided, are you sure you want to continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { action in
                self.submitDrive()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true)
        } else {
            submitDrive()
        }
    }
    
    func submitDrive() {
        self.resignFirstResponder()
        
        guard let initialPlace = initialPlaceField.text else { return }
        guard let finalPlace = finalPlaceField.text else { return }
        guard let location = initialPlaceCoordinate else { return }
        guard let location2 = finalPlaceCoordinate else { return }
        var initialTime = initialTimePicker.date
        var finalTime = finalTimePicker.date
        let date = datePicker.date
        finalTime.setSameDay(as: date)
        initialTime.setSameDay(as: date)
        let ticketNumber = ticketNumberField.text ?? ""
        let notes = notesField.text ?? ""
        
        let loadingScreen = createLoadingScreen(frame: view.frame)
        view.addSubview(loadingScreen)
        let drive = RegisteredDrive(initialCoordinates: location, finalCoordinates: location2, initialDate: initialTime, finalDate: finalTime, initPlace: initialPlace, finPlace: finalPlace, milesDriven: -1, ticketNumber: ticketNumber, notes: notes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            Task {
                try await FirestoreDatabase.shared.uploadRegisteredDrive(drive)
                GoogleSheetAssistant.shared.appendRegisteredDriveToSpreadsheet(drive, deletePreviousEntry: false)
                DispatchQueue.main.async {
                    self.showSuccessToast(message: "Created drive!")
                    loadingScreen.removeFromSuperview()
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
}

extension AddNewDriveVC: AddressLookupDelegate {
    func didChooseAddress(_ address: String, coordinate: CLLocationCoordinate2D) {
        if currentTextField == 0 {
            self.initialPlaceField.text = address
            self.initialPlaceCoordinate = coordinate
        } else if currentTextField == 1 {
            self.finalPlaceField.text = address
            self.finalPlaceCoordinate = coordinate
        }
        
        if initialPlaceField.text?.count ?? 0 > 0 && finalPlaceField.text?.count ?? 0 > 0 {
            createButton.tintColor = .accentColor
        }
    }
    
    
}

extension AddNewDriveVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case 0:
            finalPlaceField.becomeFirstResponder()
        case 1:
            ticketNumberField.becomeFirstResponder()
        case 2:
            notesField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if initialPlaceField.text != "" && finalPlaceField.text != "" {
            createButton.tintColor = .accent
        }
        else {
            createButton.tintColor = .systemGray
        }
        return true
    }
}
