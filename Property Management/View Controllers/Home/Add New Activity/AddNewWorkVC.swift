//
//  AddNewDriveVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/9/24.
//

import UIKit
import FDTake
import CoreLocation
class AddNewWorkVC: UIViewController {
    
    static let identifier = "AddNewWorkScreen"
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var initialTimePicker: UIDatePicker!
    @IBOutlet weak var finalTimePicker: UIDatePicker!
    
    @IBOutlet weak var placeField: UITextField!
    var placeCoordinate: CLLocationCoordinate2D?
    
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
        
        placeField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(placeFieldClicked)))
        camera = FDTakeController()
        camera.allowsVideo = false
        
        self.hideKeyboardWhenTappedAround()
    }
    
    @objc func placeFieldClicked() {
        let vc = storyboard?.instantiateViewController(withIdentifier: AddressLookupVC.identifier) as! AddressLookupVC
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
        
        
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
        guard let location = placeCoordinate else { return }
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
        let work = RegisteredWork(initialCoordinates: location, finalCoordinates: location, initialDate: initialTime, finalDate: finalTime, initPlace: place, finPlace: place, moneySpent: money, ticketNumber: ticketNumber, notes: notes, image: self.image ?? UIImage.checkmark)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            Task {
                
                if let image = self.image {
                    try FirebaseStorage.shared.uploadWorkReciept(work, image: image) { completion in
                        print("did upload reciept: \(completion)")
                        
                        Task {
                            try await FirestoreDatabase.shared.uploadRegisteredWork(work)
                            GoogleSheetAssistant.shared.appendRegisteredWorkToSpreadsheet(work, deletePreviousEntry: false)
                        }
                    }
                } else {
                    Task {
                        try await FirestoreDatabase.shared.uploadRegisteredWork(work)
                        GoogleSheetAssistant.shared.appendRegisteredWorkToSpreadsheet(work, deletePreviousEntry: false)
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
    
    @IBAction func cameraButtonClicked(_ sender: Any) {
        camera.present()
        camera.didGetPhoto = {
            (_ photo: UIImage, _ info: [AnyHashable : Any]) in
            
            self.cameraButton.setImage(UIImage(systemName: "icloud.and.arrow.up"), for: .normal)
            self.image = photo
            
        }
    }
    
}

extension AddNewWorkVC: AddressLookupDelegate {
    
    func didChooseAddress(_ address: String, coordinate: CLLocationCoordinate2D) {
        self.placeField.text = address
        self.placeCoordinate = coordinate
        if placeField.text?.count ?? 0 > 0 {
            createButton.tintColor = .accentColor
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

