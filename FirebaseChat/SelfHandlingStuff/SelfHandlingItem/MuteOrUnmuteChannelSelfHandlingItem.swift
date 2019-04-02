//
//  MuteOrUnmuteChannelSelfHandlingItem.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class MuteOrUnmuteChannelSelfHandlingItem: SelfHandlingItem {
    
    let channel: Channel
    let chatParticipantSetting : ChatParticipantSetting
    
    init(channel: Channel) {
        self.channel = channel
        chatParticipantSetting = ChatParticipantSetting(channelKey: channel.id, userKey: FirebaseService.currentUserKey!)
        
        super.init()
        
        refresh(nil)
    }
    
    override func refresh(_ sender: Any?) {
        
        if chatParticipantSetting.notificationsMuted {
            
            title = "Unmute Chat"
            style = .default
            image = UIImage(named: "icons8-mute_filled")
            
            action = {
                let alert = UIAlertController(title: "Are you sure?", message: "Chat will be unmuted and you will receive push notifications of new messages.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Unmute", style: .default, handler: { [weak self] (action) in
                    
                    self?.chatParticipantSetting.notificationsMuted = false
                    self?.chatParticipantSetting.save()
                    self?.refresh(nil)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                UIViewController.topMostController().present(alert, animated: true, completion: nil)
            }// End of action
            
        } else {
            
            title = "Mute Chat"
            style = .default
            image = UIImage(named: "icons8-mute")
            
            action = {
                let alert = UIAlertController(title: "Are you sure?", message: "Chat will be muted and you will not receive push notifications of new messages.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Mute", style: .destructive, handler: { [weak self] (action) in
                    
                    self?.chatParticipantSetting.notificationsMuted = true
                    self?.chatParticipantSetting.save()
                    self?.refresh(nil)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                UIViewController.topMostController().present(alert, animated: true, completion: nil)
            }// End of action
        }
        
        super.refresh(sender)
    }
}
