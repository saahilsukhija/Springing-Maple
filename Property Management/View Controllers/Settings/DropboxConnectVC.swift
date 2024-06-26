//
//  DropboxConnectVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/12/24.
//

import UIKit
import SwiftyDropbox

class DropboxConnectVC: UIViewController {

    static let identifier = "DropboxConnectScreen"
    
    @IBOutlet weak var dropboxButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(dropboxAuthCompleted), name: .dropboxAuthenticationComplete, object: nil)
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDropboxButton()
    }
    
    func updateDropboxButton() {
        let atr = NSAttributedString(string: User.shared.dropbox.isConnected ? "Disconnect Dropbox" : "Connect Dropbox", attributes: [
            .font: UIFont(name: "Montserrat-SemiBold", size: 16) ?? UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.accentColor
        ])
        dropboxButton.setAttributedTitle(atr, for: .normal)
    }
    
    @IBAction func dropboxButtonClicked(_ sender: Any) {
        if User.shared.dropbox.isConnected {
            DropboxClientsManager.unlinkClients()
            User.shared.dropbox.selectedFolder = nil
            AppDelegate.saveVariables()
            navigationController?.popToRootViewController(animated: true)
            self.showSuccessToast(message: "Unlinked dropbox")
            return
        }
        
        let scopeRequest = ScopeRequest(scopeType: .user, scopes: ["account_info.read", "files.metadata.write", "files.metadata.read", "files.content.write", "files.content.read"], includeGrantedScopes: false)
        DropboxClientsManager.authorizeFromControllerV2(
            UIApplication.shared,
            controller: self,
            loadingStatusDelegate: nil,
            openURL: { (url: URL) -> Void in UIApplication.shared.open(url, options: [:], completionHandler: nil) },
            scopeRequest: scopeRequest
        )
    }
    
    @objc func dropboxAuthCompleted() {
        
        guard User.shared.dropbox.isConnected else { print("user not authenticated in dropbox"); return }
        
        updateDropboxButton()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            DropboxAssistant.shared.getAllFolders() { folders in
                self.showFolders(folders)
            }
        }
        
    }
    
    func showFolders(_ folders: [DropboxFolder]) {
        let vc = storyboard?.instantiateViewController(withIdentifier: DropboxFolderConnectVC.identifier) as! DropboxFolderConnectVC
        vc.setupFolders(folders)
        vc.parentVC = self
        self.present(vc, animated: true)
    }
    
    func dropboxFolderChosen(_ folder: DropboxFolder) {
        User.shared.dropbox.selectedFolder = folder
        self.showSuccessToast(message: "Successfully linked Dropbox")
        self.navigationController?.popToRootViewController(animated: true)
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
