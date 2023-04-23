//
//  ViewController.swift
//  cant sleep
//
//  Created by Michael Kawwa on 2/16/19.
//  Copyright © 2019 Michael Kawwa. All rights reserved.
//

import UIKit
import Lottie
import Firebase

class ViewController: UIViewController {

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let animationView = AnimationView(name: "nightAnimation")
        animationView.play()
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = .autoReverse
        animationView.frame = CGRect(x: 0, y: 150, width: self.view.frame.width, height: 250)
        self.view.addSubview(animationView)
    }

}
