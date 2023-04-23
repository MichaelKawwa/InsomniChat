//
//  SignInViewController.swift
//  cant sleep
//
//  Created by Michael Kawwa on 3/17/19.
//  Copyright © 2019 Michael Kawwa. All rights reserved.
//

import UIKit
import Firebase

class SignInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var errorLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var signIn: UIButton!
    
    let impact = UIImpactFeedbackGenerator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.delegate = self
        emailField.delegate = self
       signIn.layer.cornerRadius = 10
        let tapRecgonizer = UITapGestureRecognizer(target: self, action: #selector(dismissTextfield))
        view.addGestureRecognizer(tapRecgonizer)
    }
    
    @IBAction func SignIn(_ sender: Any) {
        Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) { (success, error) in
            if success != nil {
                let mainVC = self.storyboard?.instantiateViewController(withIdentifier: "testView") as! TestViewController
                 self.present(mainVC, animated: true, completion: nil)
            } else {
                print(error?.localizedDescription)
                self.errorLabel.text = "wrong password or username"
                self.impact.impactOccurred()
            }
            
        }
    }
    
    @objc func dismissTextfield() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            textField.resignFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
}
