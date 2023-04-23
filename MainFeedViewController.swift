//
//  MainFeedViewController.swift
//  cant sleep
//
//  Created by Michael Kawwa on 3/17/19.
//  Copyright © 2019 Michael Kawwa. All rights reserved.
//

import UIKit
import Firebase
import Lottie
import Crashlytics

@available(iOS 10.0, *)
class MainFeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
   

    @IBOutlet var userCountLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var startButtonDesign: UIButton!
    @IBOutlet var FSDes: UIButton!
    @IBOutlet var funFactsLabel: UILabel!
    @IBOutlet var LeaveDes: UIButton!
    @IBOutlet var fullScreenDes: UIButton!
    
    let impact = UIImpactFeedbackGenerator()
    let date = Date()
    let calendar = Calendar.current
    let random = arc4random() % 2
    var array = [String]()
    var status = Bool()
    var userArray = [Int]()
    var connected = false
    var chatID = Int()
    var arrayCount: [Int] = []
    let qeue = OperationQueue()
    let group = DispatchGroup()
    var testInt = 0
    var backGroundTask: UIBackgroundTaskIdentifier = .invalid
    var inactivityTimer = Timer()
    var chosenStr = String()
    var blockedUser = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        messageTableView.estimatedRowHeight = 1000.0
             messageTableView.rowHeight = UITableView.automaticDimension
        
        
        print(array)
        let insomniacCounter = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(UpdateCounter), userInfo: nil, repeats: true)
        insomniacCounter.fire()
        
        let funFactTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(funFact), userInfo: nil, repeats: true)
        funFactTimer.fire()
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                print("Connected")
            } else {
                print("Not connected")
                var ref = Database.database().reference().child("chatGroup\(self.chatID)").child("users").child("uid").child(Auth.auth().currentUser!.uid)
                ref.removeAllObservers()
                ref.onDisconnectRemoveValue()
                ref.removeValue { (error, ref) in
                    ref.removeValue()
                    if error != nil {
                        print("failed to delete message: \(ref)")
                    }
                }
                
            }
        })


         LeaveDes.alpha = 0
        LeaveDes.layer.cornerRadius = 10
        FSDes.alpha = 0 

        
        startButtonDesign.layer.cornerRadius = 10
        
        messageTableView.delegate = self
        messageTableView.dataSource = self
        textField.delegate = self
        let tap = UITapGestureRecognizer(target: self.view, action: Selector("endEditing:"))
        self.view.addGestureRecognizer(tap)
        
        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)

        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willQuit), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeInActive), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func didBecomeActive() {
        print("did Become Active")
    }
    
    @objc func didBecomeInActive() {
        print("Did lose activity")
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
        textField.addGestureRecognizer(textTapRecgonizer)
        resetTimer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyBoardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {return}
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
        view.frame.origin.y = -keyBoardRect.height
        } else {
            view.frame.origin.y = 0
        }
    }

    let semaphore = DispatchSemaphore(value: 1)
    
    func getMessages(completion: @escaping () -> Void) {
        print("chatid for get messages \(self.chatID)")
        let refHandle = Database.database().reference().child("chatGroup\(chatID)").observe(.childAdded) { (snapShot) in
            let message = snapShot.value as? String
                 if let actualMessage = message {
                     print("actual message \(actualMessage)")
                     let usernameSet = actualMessage.components(separatedBy: ":")
                     let username = usernameSet[0]
                     if username == self.blockedUser {
                         print("blocked")
                     } else {
                        print("it worked")
                     self.array.append(actualMessage)
                     self.messageTableView.reloadData()
                     if self.array.count > 0 {
                         print(" self array \(self.array)")
                         self.messageTableView.scrollToRow(at: IndexPath(item: self.array.count - 1, section: 0), at: .bottom, animated: true)
                     }
                     completion()
                     }
                 } 
             }
 }
    
    
    @objc func resetTimer() {
        print("keyboard touchedx")
        inactivityTimer.invalidate()
        inactivityTimer = Timer.scheduledTimer(timeInterval: 60.0 * 5, target: self, selector: #selector(showWarning), userInfo: nil, repeats: false)
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
    
   @objc func UpdateCounter() {
    Database.database().reference().child("chatGroup\(self.chatID)").child("users").child("uid").observe(.value, with: { (snapShot) in
        self.userCountLabel.text = "\(snapShot.children.allObjects.count) insominiacs"
    })
    }
    
    var userCount = Int()
    
    func makeArray(completion: @escaping () -> Void) {
        for var i in 0 ..< 10 {
               i += 1
            group.enter()
            Database.database().reference().child("chatGroup\(i)").child("users").child("uid").observeSingleEvent(of: .value
                , with: { (snapShot) in
                  print(snapShot.children.allObjects)
                    self.userCount = snapShot.children.allObjects.count
                    self.arrayCount.append(self.userCount)
                    self.group.leave()
                    })
            }
        group.notify(queue: .main) {
            completion()
         }
        }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        resetTimer()
        print("dragging")
    }
    
    func sortArray() {
        let userData = ["ID": Auth.auth().currentUser?.email] as! [String : String]
        for item in arrayCount {
            print(item)
            if item < 31 {
                chatID = arrayCount.firstIndex(of: item)! + 1
                print("chatID for sort \(chatID)")
                print(chatID)
           self.getMessages {
          print("unuodated chatid: \(self.chatID)")
        self.messageTableView.scrollToRow(at: IndexPath(item: self.array.count - 1, section: 0), at: .bottom, animated: true)
        print("get messages")
                            }
                DataService.instance.updateStatus(senderID: Auth.auth().currentUser!.providerID, userData: userData, reference: Database.database().reference(withPath: "chatGroup\(chatID)").child("users"))
                    // fix the username error, as only the EULA alert shows up first, make the other alert on the other vc's
                 if Auth.auth().currentUser?.displayName != nil {
      Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("\(Auth.auth().currentUser!.displayName!) has now entered the chat.")
                       } else {
                    print("good job")
                   Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("default has now entered the chat.")
                       }
                connected = true
               break
            }
        }
    }
    
    @objc func funFact() {
        let url = URL(string: "https://uselessfacts.jsph.pl/random.json?language=en")!
        
        let request = URLRequest(url: url)
        
        let session = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("error")
            } else {
                if let data = data {
                    let jsonString = String(data: data, encoding: String.Encoding.utf8)

                    let decoder = JSONDecoder()
                    do {
                        let decodedString = try decoder.decode(fact.self, from: data)
                        print(decodedString)
                        DispatchQueue.main.async {
                            self.funFactsLabel.text = decodedString.text
                            self.funFactsLabel.lineBreakMode = .byTruncatingMiddle
                            self.funFactsLabel.adjustsFontSizeToFitWidth = true
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
        
        session.resume()
    }
    
    @IBAction func Fullscreen(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "TextingVC") as! TextingViewController
         vc.chatID = chatID
        self.present(vc, animated: true)
    }
        
    
    @IBAction func StartButton(_ sender: Any) {
       if date >= calendar.date(bySettingHour: 23, minute: 0, second: 0, of: date)! || date <= calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date)! {
         connected = true
        makeArray(completion: sortArray)
            UIView.animate(withDuration: 0.7) {
                self.startButtonDesign.alpha = 0
                self.LeaveDes.alpha = 1
                self.FSDes.alpha = 0.50
                Database.database().reference().child("chatGroup\(self.chatID)").child("users").child("uid").observe(.value, with: { (snapShot) in
                    self.userCountLabel.text = "\(snapShot.children.allObjects.count) insominiacs"
                })
                self.textField.addTarget(self, action: #selector(self.resetTimer), for: .allEvents)
                }
         } else {
        impact.impactOccurred()
        UIView.animate(withDuration: 1.5) {
            self.startButtonDesign.alpha = 0
            self.LeaveDes.alpha = 1
        }
        funFactsLabel.text = "To start chatting you must wait till 11:00pm, this chat is intended for those who have trouble sleeping or are just up late. See you then!"
        funFactsLabel.textColor = #colorLiteral(red: 1, green: 0.06170231849, blue: 0, alpha: 1)
           }
        }
  
    
    @IBAction func leaveButton(_ sender: Any) {
        connected = false
  let ref = Database.database().reference().child("chatGroup\(chatID)").child("users").child("uid").child(Auth.auth().currentUser!.uid)
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
    @IBAction func sendBtn(_ sender: Any) {
        if textField.text != " " {
            if Auth.auth().currentUser?.displayName != nil {
     Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("\(Auth.auth().currentUser!.displayName!): \(textField.text!)")
            textField.text = ""
                   } else {
    Database.database().reference().child("chatGroup\(chatID)").childByAutoId().setValue("default: \(textField.text!)")
               textField.text = ""                   }
            }
    }
    
    func feedListener(array: [String], tableView: UITableView) {
        
    }
    
    @IBOutlet weak var messageTableView: UITableView!
    
    @objc func updateTime() {
        timeLabel.text = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: DateFormatter.Style.none, timeStyle: DateFormatter.Style.short)
        let hour = calendar.component(.hour, from: date)
        let morning = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date)
        let evening = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date)
        let night = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: date)
        if date >= morning! {
            if random == 1 {
            imageView.image = UIImage(named: "dayone")
                FSDes.backgroundColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
            } else {
                imageView.image = UIImage(named: "daytwo")
                FSDes.backgroundColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
            }
        }
        if date >= evening! {
            if random == 1 {
                imageView.image = UIImage(named: "sunset")
                FSDes.backgroundColor = #colorLiteral(red: 0.2203825116, green: 0.3053183556, blue: 0.3540946245, alpha: 1)
            } else {
                imageView.image = UIImage(named: "sunset2")
            }
        }
        if date >= night! {
          imageView.image = UIImage(named: "night")
            FSDes.backgroundColor = #colorLiteral(red: 0.1759063303, green: 0.1646407545, blue: 0.3333325684, alpha: 1)
        }
    }
    
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell") as? MessageTableViewCell {
            cell.textLabel!.text = array[indexPath.row]
        if array[indexPath.row].contains("may have fallen asleep, and has been removed from the chat due to inactivity. ****") || array[indexPath.row].contains("left the chat") {
            cell.textLabel!.textColor = UIColor.red
        } else if  array[indexPath.row].contains("has now entered the chat.") {
            cell.textLabel!.textColor = UIColor.green
        } else {
            cell.textLabel!.textColor = UIColor.white
            chosenStr = array[indexPath.row]
            cell.flagButton.tag = indexPath.row
            cell.flagButton.addTarget(self, action: #selector(flagText(_:)), for: .touchUpInside)
        }
        cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping
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
                                 print("username: \(username)")
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

    func textFieldShouldReturn(_ TextField: UITextField) -> Bool {
        TextField.resignFirstResponder()
        return true
    }

}


struct fact: Codable {
   var id: String
   var text: String
 
    init(id: String, text: String) {
        self.id = id
        self.text = text
    }
    
  }


extension MainFeedViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
