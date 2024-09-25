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
    
    var baseFolder: DropboxFolder?
    var folders: [DropboxFolder] = []
    var parentVC: UIViewController!
    var isRoot: Bool = false
    var path: String = ""
    var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        doneButton = UIBarButtonItem(title: "Select", style: .done, target: self, action: #selector(doneButtonClicked))
        self.navigationItem.title = baseFolder == nil ? "Choose folder to connect" : baseFolder?.name ?? ""
        self.navigationItem.rightBarButtonItem = doneButton
        
        if isRoot {
            doneButton.tintColor = .systemGray
        } else {
            doneButton.tintColor = .accent
        }
    }
    
    func setupFolders(_ folders: [DropboxFolder], isRoot: Bool, baseFolder: DropboxFolder?, path: String) {
        self.folders = folders
        self.isRoot = isRoot
        self.baseFolder = baseFolder
        self.path = path
    }

    func dropboxFolderChosen(_ folder: DropboxFolder) {
        navigationController?.popViewController(animated: true)
        if(isRoot) {
            (parentVC as! DropboxConnectVC).dropboxFolderChosen(folder)
            navigationController?.popToRootViewController(animated: true)
            self.dismiss(animated: true)
        } else {
            (parentVC as! DropboxFolderConnectVC).dropboxFolderChosen(folder)
        }
    }
    
    @objc func doneButtonClicked() {
        guard let baseFolder = baseFolder else { return }
        dropboxFolderChosen(baseFolder)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = storyboard?.instantiateViewController(withIdentifier: DropboxFolderConnectVC.identifier) as! DropboxFolderConnectVC
        DropboxAssistant.shared.getAllFolders(at: path + "/\(folders[indexPath.row].name ?? "")") { [self] result in
            vc.setupFolders(result, isRoot: false, baseFolder: folders[indexPath.row], path: path + "/\(folders[indexPath.row].name ?? "")")
            vc.parentVC = self
            self.navigationController?.pushViewController(vc, animated: true)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
    
    
    
}
