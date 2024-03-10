//
//  ChooseActivityVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/9/24.
//

import UIKit

class ChooseActivityVC: UIViewController {
    
    @IBOutlet weak var driveView: UIView!
    @IBOutlet weak var workView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        driveView.layer.cornerRadius = 10
        driveView.layer.borderWidth = 1
        driveView.layer.borderColor = UIColor.systemGray4.cgColor
        
        workView.layer.cornerRadius = 10
        workView.layer.borderWidth = 1
        workView.layer.borderColor = UIColor.systemGray4.cgColor
        
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
