//
//  DeleteChannelSelfHandlingItem.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class DeleteChannelSelfHandlingItem: SelfHandlingItem {
    
    let channel: Channel
    private let completion: (()->Void)?
    
    private var futureAdmin: FirebaseUser?
    
    init(channel: Channel, completion: (()->Void)? = nil) {
        self.channel = channel
        self.completion = completion
        
        super.init()
        
        action = { [weak self] in
            
            let setting = channel.currentUserSetting()!
            let noOtherAdminsLeft = channel.otherParticipants.filter({ channel.setting(ofParticipant: $0).chatParticipantRole == .admin }).count == 0
            if setting.chatParticipantRole == .admin && noOtherAdminsLeft {
                
                var name = channel.name
                if name == nil {
                    name = "with " + channel.participantsString
                }
                
                let alert = UIAlertController(title: "Delete Chat?", message: "You are the last admin in the conversation \(name ?? "Chat"). You'll need to select a new admin if you delete it.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] (action) in
                    
                    
                    // TODO: Add a new admin picker
//                    let vc : FriendsPickerViewController = FriendsPickerViewController.instantiate()
//                    vc.delegate = self
//                    vc.title = "Select New Admin"
//                    let friends = channel.otherActiveParticipants.filter({ channel.setting(ofParticipant: $0).chatParticipantRole != .admin })
//                    vc.customFriends = friends
//
//                    NavigationService.shared.show(viewController: vc)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                UIViewController.topMostController().present(alert, animated: true, completion: nil)
                
            } else {
                self?.presentPopup()
            }
        }
        title = "Leave channel"
    }
    
    func presentPopup() {
        var name = channel.name
        if name == nil {
            name = "with " + channel.participantsString
        }
        
        let alert = UIAlertController(title: "Are you sure?", message: "The conversation \(name ?? "Chat") will be removed from your list, the messages will be kept and can be restored later.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] (action) in
            
            if let channel = self?.channel {
                FirebaseService.leaveChannel(channel)
                
                if let futureAdmin = self?.futureAdmin {
                    // Pick the new admin if this is the admin
                    FirebaseService.makeAdminFromParticipant(participant: futureAdmin, inChannel: channel)
                }
                self?.completion?()
            }
            
            self?.refresh(nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        UIViewController.topMostController().present(alert, animated: true, completion: nil)
    }
    
    // ----------------------------------------------------
    // MARK: - FriendsPickerViewControllerDelegate
    // ----------------------------------------------------
    
    func friendsPickerDidSelect(friend: FirebaseUser) {
        
        futureAdmin = friend
        presentPopup()
    }
    
}
