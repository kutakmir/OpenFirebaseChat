//
//  RemoveParticipantFromChannelSelfHandlingItem.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class RemoveParticipantFromChannelSelfHandlingItem: SelfHandlingItem {
    
    var user: FirebaseUser
    let channel: Channel
    private let completion: (()->Void)?
    
    init(channel: Channel, user: FirebaseUser, completion: (()->Void)? = nil) {
        self.user = user
        self.channel = channel
        self.completion = completion
        
        super.init()
        
        
        action = presentPopup
        title = "Remove"
    }
    
    func presentPopup() {
        
        let name = user.name ?? "this person"
        
        let alert = UIAlertController(title: "Are you sure?", message: "You will remove \(name) from the Chat.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { [weak self] (action) in
            
            if let channel = self?.channel, let user = self?.user {
                FirebaseService.removeParticipant(participant: user, fromChannel: channel)
                self?.completion?()
            }
            
            self?.refresh(nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        UIViewController.topMostController().present(alert, animated: true, completion: nil)
    }
    
}
