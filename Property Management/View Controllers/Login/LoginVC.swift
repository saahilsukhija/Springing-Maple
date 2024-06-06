//
//  LoginVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/2/24.
//

import UIKit
import GoogleSignIn
import FirebaseAuth

class LoginVC: UIViewController {

    static let identifier = "LoginScreen"
    
    @IBOutlet weak var googleSignInButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        googleSignInButton.dropShadow(radius: 3)
        NotificationCenter.default.addObserver(self, selector: #selector(signInGoogleCompleted), name: .signInGoogleCompleted, object: nil)
        
    }
    
    @objc func signInGoogleCompleted() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func signInWithGoogleTapped(_ sender: Any) {
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            guard error == nil else {
                return
            }
            
            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                return
            }
            print("ID: " + idToken)
            // let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            let credential = GoogleAuthProvider.credential(withIDToken: result?.user.idToken?.tokenString ?? "",
                                                           accessToken: result?.user.accessToken.tokenString ?? "")
            Auth.auth().signIn(with: credential) { [self] result, error in
                self.showSignInToast()
                
                Task {
                    do {
                        let team = try await FirestoreDatabase.shared.getUserTeam()
                        DispatchQueue.main.async {
                            if team == nil {
                                
                                let vc = self.storyboard!.instantiateViewController(withIdentifier: NewTeamVC.identifierWithoutNavController)
                                vc.modalPresentationStyle = .fullScreen
                                self.navigationController?.pushViewController(vc, animated: true)
                                return
                            }
                            else {
                                User.shared.team = team
                                self.dismiss(animated: true, completion: nil)
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
            }


        }
    }
    
    func showSignInToast() {
        
        if(GIDSignIn.sharedInstance.currentUser != nil) {
            showAnimationToast(animationName: "LoginSuccess", message: "Welcome, \(GIDSignIn.sharedInstance.currentUser!.profile!.givenName!)")
        }
        else {
            print("not signed in")
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
