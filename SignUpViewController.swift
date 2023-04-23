//
//  SignUpViewController.swift
//  cant sleep
//
//  Created by Michael Kawwa on 3/15/19.
//  Copyright © 2019 Michael Kawwa. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseUI

class SignUpViewController: UIViewController, UITextFieldDelegate {
   
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet var errorLabel: UILabel!
    
    
    @IBOutlet weak var SignUp: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.SignUp.layer.cornerRadius = 10
        emailField.delegate = self
        userNameField.delegate = self
        passwordField.delegate = self
        emailField.textContentType = .emailAddress
        let tapRecgonizer = UITapGestureRecognizer(target: self, action: #selector(dismissTextfield))
        view.addGestureRecognizer(tapRecgonizer)
    }
    
    @IBAction func SignUpButton(_ sender: Any) {
        if userNameField.text! != "" {
            if userNameField.text!.count <= 12 {
        AuthService.instance.registerUser(withEmail: emailField.text!, andPassword: passwordField.text!, andUserName: userNameField.text!) { (success, error) in
            if success {
              var mainVC = self.storyboard?.instantiateViewController(withIdentifier: "testView") as! TestViewController
                self.present(mainVC, animated: true, completion: nil)
                print("success")
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = self.userNameField.text
                changeRequest?.commitChanges(completion: { (error) in
                    
                    if error == nil {
                        print("display name: \(self.userNameField.text)")
                    }
                })
            } else {
                print(" email error: \(error)")
                self.errorLabel.text = error?.localizedDescription
            }
          }
            } else {
                self.errorLabel.text = "Username must be under 12 charcters."
            }
            
        } else {
            self.errorLabel.text = "A username must be provided!"
        }
    }
    
    @objc func dismissTextfield() {
        view.endEditing(true)
    }
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            userNameField.becomeFirstResponder()
        } else if textField == userNameField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            textField.resignFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }


}
