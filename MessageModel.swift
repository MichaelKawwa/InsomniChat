//
//  MessageModel.swift
//  cant sleep
//
//  Created by Michael Kawwa on 3/21/19.
//  Copyright © 2019 Michael Kawwa. All rights reserved.
//

import Foundation

class Message {
    private var _content: String
    private var _senderID: String
    
    var content: String {
        return _content
    }
    
    var senderID: String {
        return _senderID
    }
    
    init(content: String,senderID: String) {
        self._content = content
        self._senderID = senderID
    } 
    
}
