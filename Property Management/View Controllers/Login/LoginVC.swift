//
//  LoginVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/2/24.
//

import UIKit
import GoogleSignIn

class LoginVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
            self.showSignInToast()
            self.dismiss(animated: true, completion: nil)
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
