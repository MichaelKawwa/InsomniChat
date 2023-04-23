//
//  TestViewController.swift
//  cant sleep
//
//  Created by Michael Kawwa on 6/29/19.
//  Copyright © 2019 Michael Kawwa. All rights reserved.
//

import UIKit
import Lottie
import Firebase
import Crashlytics

class TestViewController: UIViewController {
     
    @IBOutlet var chatDes: UIButton!
    weak var actionToEnable : UIAlertAction?
    
    @IBAction func chatButton(_ sender: Any) {
     showAlert()
    }
    
    @IBAction func findServers(_ sender: Any) {
       showAlert()
    }
    
    func showAlert() {
        if Auth.auth().currentUser?.displayName == nil {
                          print("nil")
                          let alert = UIAlertController(title: "What would you like your username to be?", message: "this is the name that will be publicly displayed. username must be under 12 charcters.", preferredStyle: .alert)
                          alert.addTextField()
                          alert.textFields![0].addTarget(self, action: "textChanged:", for: .editingChanged)
                          alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: nil))
                          alert.actions[0].isEnabled = false
                          self.actionToEnable = alert.actions[0]
                              let username = alert.textFields![0].text
                          self.present(alert, animated: true, completion: nil)
                          }
    }
    
    override func viewDidLoad() {

        chatDes.layer.cornerRadius = 10
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
            self.isModalInPopover = true
        } else {
            // Fallback on earlier versions
        }
        super.viewDidLoad()
        let animationView = AnimationView(name: "nightAnimation")
        animationView.backgroundColor = #colorLiteral(red: 0.3513054252, green: 0.3494670987, blue: 0.4125052094, alpha: 1)
        animationView.play()
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = .autoReverse
        animationView.frame = CGRect(x: 0, y: 150, width: self.view.frame.width, height: 200)
        self.view.addSubview(animationView)
                    
    }
    
    override func viewDidAppear(_ animated: Bool) {
      
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")

         if launchedBefore {
                   print("Not first launch.")
                     } else {
                      print("First launch")
            UserDefaults.standard.set(true, forKey: "launchedBefore")
      let eulaAlert = UIAlertController(title: "End User License Agreement", message: "By using InsomniChat you agree to the terms of service and privacy policy. InsomniChat has no tolerance for objectionable content or abusive users. You'll be banned for any inappropriate usage.", preferredStyle: .alert)
        eulaAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
         self.present(eulaAlert, animated: true)
               }
        
        }
    
    @objc func textChanged(_ sender: Any) {
        let textField = sender as! UITextField
        if textField.text != "" && textField.text!.count <= 12 {
            self.actionToEnable?.isEnabled = true
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = textField.text
            changeRequest?.commitChanges(completion: { (error) in
                 print("error")
            })
        } else {
          self.actionToEnable?.isEnabled = false
          print("username not valid")
        }
    }
        
}

