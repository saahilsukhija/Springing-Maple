//
//  AddNewDriveVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/9/24.
//

import UIKit

class AddNewDriveVC: UIViewController {

    static let identifier = "AddNewDriveScreen"
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var initialTimePicker: UIDatePicker!
    @IBOutlet weak var finalTimePicker: UIDatePicker!
    
    @IBOutlet weak var initialPlaceField: UITextField!
    @IBOutlet weak var finalPlaceField: UITextField!
    @IBOutlet weak var ticketNumberField: UITextField!
    @IBOutlet weak var notesField: UITextField!
    
    var createButton: UIBarButtonItem!
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
        
        self.hideKeyboardWhenTappedAround()
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
        let initialPlace = initialPlaceField.text
        let finalPlace = finalPlaceField.text
        var initialTime = initialTimePicker.date
        var finalTime = finalTimePicker.date
        let date = datePicker.date
        finalTime.setSameDay(as: date)
        initialTime.setSameDay(as: date)
        let ticketNumber = ticketNumberField.text ?? ""
        let notes = notesField.text ?? ""
        
        let loadingScreen = createLoadingScreen(frame: view.frame)
        view.addSubview(loadingScreen)
        LocationManager().getReverseGeoCodedLocation(address: initialPlace ?? "") { location, placemark, error in
            if let error = error {
                self.showFailureToast(message: "Please enter a valid initial address")
                loadingScreen.removeFromSuperview()
            } else {
                LocationManager().getReverseGeoCodedLocation(address: finalPlace ?? "") { location2, placemark2, error2 in
                    if let error2 = error2 {
                        self.showFailureToast(message: "Please enter a valid final address")
                        loadingScreen.removeFromSuperview()
                    } else {
                        let drive = RegisteredDrive(initialCoordinates: location!.coordinate, finalCoordinates: location2!.coordinate, initialDate: initialTime, finalDate: finalTime, initPlace: initialPlace, finPlace: finalPlace, ticketNumber: ticketNumber, notes: notes)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            Task {
                                try await FirestoreDatabase.shared.uploadRegisteredDrive(drive)
                                GoogleSheetAssistant.shared.appendRegisteredDriveToSpreadsheet(drive)
                                DispatchQueue.main.async {
                                    self.showSuccessToast(message: "Created drive!")
                                    loadingScreen.removeFromSuperview()
                                    self.navigationController?.popToRootViewController(animated: true)
                                }
                            }
                        }
                    }
                }
            }
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
