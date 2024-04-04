//
//  ChooseActivityVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/9/24.
//

import UIKit

class ChooseActivityVC: UIViewController {
    
    static let identifier = "ChooseActivityScreen"
    @IBOutlet weak var driveView: UIView!
    @IBOutlet weak var workView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        driveView.layer.cornerRadius = 20
        driveView.layer.borderWidth = 0
        driveView.dropShadow(radius: 3)
        
        workView.layer.cornerRadius = 20
        workView.layer.borderWidth = 0
        workView.dropShadow(radius: 3)
        
        driveView.isUserInteractionEnabled = true
        workView.isUserInteractionEnabled = true
        
        driveView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(driveButtonClicked)))
        workView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(workButtonClicked)))
    }
    
    @objc func driveButtonClicked() {
        let vc = storyboard?.instantiateViewController(withIdentifier: AddNewDriveVC.identifier) as! AddNewDriveVC
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func workButtonClicked() {
        let vc = storyboard?.instantiateViewController(withIdentifier: AddNewWorkVC.identifier) as! AddNewWorkVC
        navigationController?.pushViewController(vc, animated: true)
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
