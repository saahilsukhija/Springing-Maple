//
//  AddNewDriveVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/9/24.
//

import UIKit
import FDTake

class AddNewWorkVC: UIViewController {
    
    static let identifier = "AddNewWorkScreen"
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var initialTimePicker: UIDatePicker!
    @IBOutlet weak var finalTimePicker: UIDatePicker!
    
    @IBOutlet weak var placeField: UITextField!
    @IBOutlet weak var ticketNumberField: UITextField!
    @IBOutlet weak var moneyField: UITextField!
    @IBOutlet weak var notesField: UITextField!
    
    @IBOutlet weak var cameraButton: UIButton!
    
    var createButton: UIBarButtonItem!
    
    var camera: FDTakeController!
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigationController!.title = "Create Work"
        
        createButton = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(createButtonClicked))
        createButton.tintColor = .systemGray
        self.navigationItem.rightBarButtonItems = [createButton]
        
        placeField.tag = 0
        placeField.delegate = self
        
        ticketNumberField.tag = 1
        ticketNumberField.delegate = self
        
        moneyField.tag = 2
        moneyField.delegate = self
        
        notesField.tag = 3
        notesField.delegate = self
        notesField.returnKeyType = .done
        
        camera = FDTakeController()
        camera.allowsVideo = false
        
        self.hideKeyboardWhenTappedAround()
    }
    
    @objc func createButtonClicked() {
        guard placeField.text != "" else {
            self.showFailureToast(message: "Must give an address")
            return
        }
        
        if ticketNumberField.text == "" {
            let alert = UIAlertController(title: "No Ticket Number Given!", message: "No ticket number was provided, are you sure you want to continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { action in
                self.submitWork()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true)
        } else {
            submitWork()
        }
    }
    
    func submitWork() {
        self.resignFirstResponder()
        let place = placeField.text ?? ""
        var initialTime = initialTimePicker.date
        var finalTime = finalTimePicker.date
        let date = datePicker.date
        finalTime.setSameDay(as: date)
        initialTime.setSameDay(as: date)
        let ticketNumber = ticketNumberField.text ?? ""
        let money = Double(moneyField.text ?? "0") ?? 0
        let notes = notesField.text ?? ""
        
        let loadingScreen = createLoadingScreen(frame: view.frame)
        view.addSubview(loadingScreen)
        LocationManager().getReverseGeoCodedLocation(address: place) { location, placemark, error in
            if let error = error {
                self.showFailureToast(message: "Please enter a valid address")
                loadingScreen.removeFromSuperview()
            } else {
                let work = RegisteredWork(initialCoordinates: location!.coordinate, finalCoordinates: location!.coordinate, initialDate: initialTime, finalDate: finalTime, initPlace: place, finPlace: place, moneySpent: money, ticketNumber: ticketNumber, notes: notes, image: self.image ?? UIImage.checkmark)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    Task {
                        
                        if let image = self.image {
                            try FirebaseStorage.shared.uploadWorkReciept(work, image: image) { completion in
                                print("did upload reciept: \(completion)")
                                
                                Task {
                                    try await FirestoreDatabase.shared.uploadRegisteredWork(work)
                                    GoogleSheetAssistant.shared.appendRegisteredWorkToSpreadsheet(work)
                                }
                            }
                        } else {
                            Task {
                                try await FirestoreDatabase.shared.uploadRegisteredWork(work)
                                GoogleSheetAssistant.shared.appendRegisteredWorkToSpreadsheet(work)
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.showSuccessToast(message: "Created work!")
                            loadingScreen.removeFromSuperview()
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                    
                    
                }
            }
        }
    }
    
    @IBAction func cameraButtonClicked(_ sender: Any) {
        camera.present()
        camera.didGetPhoto = {
            (_ photo: UIImage, _ info: [AnyHashable : Any]) in
            
            self.cameraButton.setImage(UIImage(systemName: "icloud.and.arrow.up"), for: .normal)
            self.image = photo
            
        }
    }
    
}

extension AddNewWorkVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case 0:
            ticketNumberField.becomeFirstResponder()
        case 1:
            moneyField.becomeFirstResponder()
        case 2:
            notesField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if placeField.text != "" {
            createButton.tintColor = .accent
        }
        else {
            createButton.tintColor = .systemGray
        }
        return true
    }
}

