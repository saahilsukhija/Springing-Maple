//
//  MemberVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/24/24.
//

import UIKit

class MemberVC: UIViewController {
    
    static let identifier = "MemberScreen"
    
    @IBOutlet weak var tableView: UITableView!
    
    var closeButton: UIBarButtonItem!
    
    var members: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        closeButton = UIBarButtonItem(title: "Close", image: UIImage(systemName: "xmark"), target: self, action: #selector(closeButtonClicked))
        closeButton.tintColor = .darkAccent
        self.navigationItem.leftBarButtonItem = closeButton
        
        tableView.delegate = self
        tableView.dataSource = self
        
        loadMembers()
    }
    
    @objc func closeButtonClicked() {
        self.dismiss(animated: true)
    }
    
    func loadMembers() {
        Task {
            
            do {
                self.members = try await FirestoreDatabase.shared.getEmails(in: User.shared.team!)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                
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

extension MemberVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MemberCell.identifier) as! MemberCell
        cell.setup(with: members[indexPath.row])
        
        //Separator Full Line
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        return cell
    }
}
