//
//  LeaveChannelSelfHandlingItem.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class LeaveChannelSelfHandlingItem: SelfHandlingItem {

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
                
                let _ = UIAlertController.presentOKAlertWithTitle("You are the last admin in this chat", message: "Please select who should be the admin after you leave.") { [weak self] in
                    
                    // Add the admin picker here
                    
//                    let vc : FriendsPickerViewController = FriendsPickerViewController.instantiate()
//                    vc.delegate = self
//                    let friends = channel.otherActiveParticipants.filter({ channel.setting(ofParticipant: $0).chatParticipantRole != .admin })
//                    vc.customFriends = friends
//
//                    NavigationService.shared.show(viewController: vc)
                }
                
            } else {
                self?.presentPopup()
            }
        }
        title = "Leave channel"
    }
    
    func presentPopup() {
        
        
        let alert = UIAlertController(title: "Are you sure?", message: "You will leave the Chat.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive, handler: { [weak self] (action) in
            
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
