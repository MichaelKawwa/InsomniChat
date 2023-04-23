//
//  ChatsViewController.swift
//  cant sleep
//
//  Created by Michael Kawwa on 8/24/19.
//  Copyright © 2019 Michael Kawwa. All rights reserved.
//

import UIKit
import Firebase

class ChatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
 
    let chatsArray = [String]()
    let date = Date()
    let calendar = Calendar.current
    let impact = UIImpactFeedbackGenerator()
    
    @IBOutlet var ChatsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ChatsTableView.delegate = self
        ChatsTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if date >= calendar.date(bySettingHour: 23
            , minute: 0, second: 0, of: date)! || date <= calendar.date(bySettingHour:  7, minute: 0, second: 0, of: date)! {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "TextingVC") as? TextingViewController
        vc?.chatID = indexPath.row + 1
        present(vc!, animated: true)
        } else {
            impact.impactOccurred()
            let alert = UIAlertController(title: "Chats are only available after 11pm.", message: "These chats are meant for those who have sleeping problems, if your up late and feeling lonely come and chat with some other insomniacs!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = ChatsTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ChatsTableViewCell {
            cell.initCell(chatGroupNum: indexPath.row + 1)
        return cell
        } else {
            return UITableViewCell()
        }
    }
    


}
