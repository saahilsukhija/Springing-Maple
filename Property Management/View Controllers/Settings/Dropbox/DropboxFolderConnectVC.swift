//
//  DropboxFolderConnectVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/12/24.
//

import UIKit

class DropboxFolderConnectVC: UIViewController {

    static let identifier = "DropboxFolderConnectScreen"
    
    @IBOutlet weak var tableView: UITableView!
    
    var folders: [DropboxFolder] = []
    var parentVC: DropboxConnectVC!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setupFolders(_ folders: [DropboxFolder]) {
        self.folders = folders
    }


}

extension DropboxFolderConnectVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DropboxFolderConnectCell.identifier) as! DropboxFolderConnectCell
        cell.setup(with: folders[indexPath.row])
        return cell
    }
    
    
    
}
