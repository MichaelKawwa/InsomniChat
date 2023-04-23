//
//  TextingViewController.swift
//  cant sleep
//
//  Created by Michael Kawwa on 8/28/19.
//  Copyright © 2019 Michael Kawwa. All rights reserved.
//

import UIKit
import Firebase
import Crashlytics
 
class TextingViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var chatLabel: UILabel!
    @IBOutlet var insomniacCount: UILabel!
    @IBOutlet var textTableView: UITableView!
    @IBOutlet var keyboard: UITextField!
    
    var array = [String]()
    var chatID = Int()
    let impact = UIImpactFeedbackGenerator()
    var inactivityTimer = Timer()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ref = DataService.instance.REF_Chats.child("uid").child(Auth.auth().currentUser!.uid)
        print("ref \(ref)")
        ref.onDisconnectRemoveValue()
        
        self.keyboard.addTarget(self, action: #selector(self.resetTimer), for: .allEvents)
        
        joinChat()
        
    
        textTableView.delegate = self
        textTableView.dataSource = self
        self.keyboard.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(bringDownTextField))
        view.addGestureRecognizer(tap)
        let insomniacTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(UpdateCounter), userInfo: nil, repeats: true)
        chatLabel.text = "Chat \(chatID)"
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willQuit), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        self.getMessages {
            self.textTableView.scrollToRow(at: IndexPath(item: self.array.count - 1, section: 0), at: .bottom, animated: true)
        }
        
    }
    
    @objc func willQuit() {
        var ref = Database.database().reference().child("chatGroup\(chatID)").child("users").child("uid").child(Auth.auth().currentUser!.uid)
        ref.removeAllObservers()
        ref.onDisconnectRemoveValue()
        ref.removeValue { (error, ref) in
            ref.removeValue()
            if error != nil {
                print("failed to delete message: \(ref)")
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        let tapRecgonizer = UITapGestureRecognizer(target: self, action: #selector(resetTimer))
        view.addGestureRecognizer(tapRecgonizer)
        let textTapRecgonizer = UITapGestureRecognizer(target: self, action: #selector(resetTimer))
        textTapRecgonizer.delegate = self
        keyboard.addGestureRecognizer(textTapRecgonizer)
        resetTimer()
    }
    
    func joinChat() {
        let userData = ["ID": Auth.auth().currentUser?.email] as! [String : String]
        // updates the database with the user and sends the confirmation for other users.
        DataService.instance.updateStatus(senderID: Auth.auth().currentUser!.providerID, userData: userData, reference: Database.database().reference(withPath: "chatGroup\(chatID)").child("users"))
        if Auth.auth().currentUser?.displayName != nil {
        Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("\(Auth.auth().currentUser!.displayName!) has now entered the chat.")
        } else {
    Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("default has now entered the chat.")
        }
    }
    
    @objc func toggle() {
        self.keyboard.becomeFirstResponder()
    }
    
    func getMessages(completion: @escaping () -> Void) {
        let refHandle = Database.database().reference().child("chatGroup\(chatID)").observe(.childAdded) { (snapShot) in
            let message = snapShot.value as? String
            if let actualMessage = message {
                print("actual message \(actualMessage)")
                let usernameSet = actualMessage.components(separatedBy: ":")
                let username = usernameSet[0]
                if username == self.blockedUser {
                    print("blocked")
                } else {
                self.array.append(actualMessage)
                self.textTableView.reloadData()
                if self.array.count > 0 {
                    print(" self array \(self.array)")
                    self.textTableView.scrollToRow(at: IndexPath(item: self.array.count - 1, section: 0), at: .bottom, animated: true)
                }
                completion()
                }
            }
        }
    }
    
    @objc func UpdateCounter() {
        Database.database().reference().child("chatGroup\(self.chatID)").child("users").child("uid").observe(.value, with: { (snapShot) in
            self.insomniacCount.text = "\(snapShot.children.allObjects.count) online"    })
    }
    
    
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyBoardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {return}
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            view.frame.origin.y = -keyBoardRect.height
        } else {
            view.frame.origin.y = 0
        }
    }

    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @IBAction func send(_ sender: Any) {
          if keyboard.text != " " {
                  if Auth.auth().currentUser?.displayName != nil {
           Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("\(Auth.auth().currentUser!.displayName!): \(keyboard.text!)")
                  keyboard.text = ""
                         } else {
          Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("default: \(keyboard.text!)")
                     keyboard.text = ""
            }
        }
    }
    
    @IBAction func backButton(_ sender: Any) {
        // leave the chat
        let ref = Database.database().reference().child("chatGroup\(chatID)").child("users").child("uid").child(Auth.auth().currentUser!.uid)
        if Auth.auth().currentUser?.displayName != nil {
        Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("**** \(Auth.auth().currentUser!.displayName!) left the chat.")
        } else {
             Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("**** default left the chat.")
        }
        ref.removeAllObservers()
        ref.onDisconnectRemoveValue()
        ref.removeValue { (error, ref) in
            ref.removeValue()
            if error != nil {
                print("failed to delete message: \(ref)")
            }
        }
        let VC = self.storyboard?.instantiateViewController(withIdentifier: "testView") as! TestViewController
        self.present(VC, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        keyboard.resignFirstResponder()
        return false
    }
    
    @objc func bringDownTextField() {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        resetTimer()
        print("dragging")
    }
    
    
    @objc func resetTimer() {
        print("keyboard touchedx")
        inactivityTimer.invalidate()
        inactivityTimer = Timer.scheduledTimer(timeInterval: 60.0 * 10, target: self, selector: #selector(showWarning), userInfo: nil, repeats: false)
    }
    
    @objc func showWarning() {
        let timer = Timer.scheduledTimer(timeInterval: 7.0, target: self, selector: #selector(removeUser), userInfo: nil, repeats: false)
        let alert = UIAlertController(title: "Are you still with us?", message: "due to your inactivity we suspect you've fallen asleep, this message is to see if you are still awake.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "I'm awake!", style: .default, handler: { (action) in
            self.resetTimer()
             timer.invalidate()
            print("timer restarted")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func removeUser() {
        // user is now deemed inactive
        self.dismiss(animated: true, completion: nil)
        let ref = Database.database().reference().child("chatGroup\(chatID)").child("users").child("uid").child(Auth.auth().currentUser!.uid)
         if Auth.auth().currentUser?.displayName != nil {
              Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("**** \(Auth.auth().currentUser!.displayName!) may have fallen asleep, and has been removed from the chat due to inactivity. ****")
              } else {
                   Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("**** default may have fallen asleep, and has been removed from the chat due to inactivity. ****")
              }
        ref.removeValue { (error, ref) in
            ref.removeValue()
            let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let mainVC = storyBoard.instantiateViewController(withIdentifier: "testView")
            self.present(mainVC, animated: true, completion: nil)
            if error != nil {
                print("failed to delete message: \(ref)")
            }
        }
    }
    
    var chosenStr = String()
    var blockedUser = String()
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = textTableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as? TextingTableViewCell {
            cell.textLabel?.textColor = .white
            cell.textLabel!.text = array[indexPath.row]
            cell.flagButton.tag = indexPath.row
            if array[indexPath.row].contains("may have fallen asleep, and has been removed from the chat due to inactivity. ****") || array[indexPath.row].contains("left the chat") {
                cell.textLabel?.textColor = UIColor.red
            } else if  array[indexPath.row].contains("has now entered the chat.") {
                cell.textLabel?.textColor = UIColor.green
            } else {
                cell.textLabel?.textColor = UIColor.white
                chosenStr = array[indexPath.row]
                cell.flagButton.addTarget(self, action: #selector(flagText(_:)), for: .touchUpInside)
            }
            cell.textLabel?.numberOfLines = 0
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    
    @objc func flagText(_ sender: UIButton) {
        print("comment \(array[sender.tag]) has been flagged.")
        let alertController = UIAlertController(title: "Report Text", message: "Why would you like to report this message? It will be sent to our team and reviewed.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "rude or offensive", style: .default, handler: { (action) in
            self.sendToDevolper(title: action.title!, flaggedText: self.array[sender.tag])
        }))
        alertController.addAction(UIAlertAction(title: "higly inappropriate", style: .default, handler: { (action) in
            self.sendToDevolper(title: action.title!, flaggedText: self.array[sender.tag])
        }))
        alertController.addAction(UIAlertAction(title: "spam", style: .default, handler: { (action) in
            self.sendToDevolper(title: action.title!, flaggedText: self.array[sender.tag])
        }))
        alertController.addAction(UIAlertAction(title: "contains a threat", style: .default, handler: { (action) in
            self.sendToDevolper(title: action.title!, flaggedText: self.array[sender.tag])
        }))
        alertController.addAction(UIAlertAction(title: "other", style: .default, handler: { (action) in
            self.sendToDevolper(title: action.title!, flaggedText: self.array[sender.tag])
        }))
                      let delimiter = ":"
                       let chatstr = self.chosenStr.components(separatedBy: delimiter)
                       let username = chatstr[0]
        alertController.addAction(UIAlertAction(title: "Block", style: .destructive , handler: { (action) in
            let confirmController = UIAlertController(title: "Are you sure?", message: "You will not receive anymore chats from \(username) if blocked.", preferredStyle: .alert)
            confirmController.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action) in
                print("blocked")
                if username != Auth.auth().currentUser?.displayName {
                    self.blockedUser = username
                }
            }))
            confirmController.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { (action) in
                print("cancel")
            }))
            self.present(confirmController, animated: true, completion: nil)
               }))
        alertController.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))

        self.present(alertController, animated: true, completion: nil)
    }
    
    func sendToDevolper(title: String, flaggedText: String) {
        Database.database().reference().child("flaggedTexts").setValue("flagged: \(flaggedText) for reason \(title) ")
    }
    
}

extension TextingViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

