//
//  ChannelTableViewCell.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class ChannelTableViewCell: SelfHandlingTableViewCell, Configurable {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: TimestampLabel!
    @IBOutlet weak var unreadMessagesIndicator: UIView!
    @IBOutlet weak var lastMessageLabel: UILabel!
    
    var deleteChannelSelfHandlingItem : DeleteChannelSelfHandlingItem?
    
    private var channel : Channel?
    
    func configure(item: Any) {
        if let item = item as? Channel {
            configure(channel: item)
        }
    }
    
    func configure(channel: Channel) {
        self.channel = channel
        titleLabel.text = channel.name
        
        deleteChannelSelfHandlingItem = DeleteChannelSelfHandlingItem(channel: channel, completion: {
            
        })
        
        // Only show the other participant's nickname as a name of the channel if there are two participants (one of them being the current user)
        if channel.participants.count == 2 && channel.name == nil {
            nameLabel.text = " "
            
            let string = channel.participantsString
            if string.count > 0 {
                nameLabel.text = channel.participantsString
            } else {
                channel.attachParticipants { [weak self] in
                    
                    DispatchQueue.main.async {
                        let text = channel.participantsString
                        if text.count > 0 {
                            self?.nameLabel.text = text
                        } else {
                            channel.attachOnce {
                                
                                DispatchQueue.main.async {
                                    self?.nameLabel.text = channel.name
                                }
                            }
                        }
                    }
                }
            }
        } else {
            nameLabel.text = nil
        }
        
        unreadMessagesIndicator.isHidden = true
        if let setting = channel.currentUserSetting() {
            setting.observeAndKeepAttached { [weak self] in
                
                DispatchQueue.main.async {
                    // Check for the read flag
                    self?.unreadMessagesIndicator.isHidden = !setting.hasUnreadMessages
                }
            }
        }
        
        if let message = channel.lastMessageNested {
            dateLabel.timestamp = message.timestamp
            lastMessageLabel.text = message.text
        }
    }
    
    func clearUI() {
        titleLabel.text = nil
        nameLabel.text = nil
        lastMessageLabel.text = nil
        unreadMessagesIndicator.isHidden = true
        dateLabel.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        addGestureRecognizer(longPress)
        
        clearUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        clearUI()
    }
    
    @objc func longPressed(_ sender: UILongPressGestureRecognizer) {
        deleteChannelSelfHandlingItem?.action()
        
//        guard let channel = channel else { return }
//        var name = channel.name
//        if name == nil {
//            name = "with " + channel.participantsString
//        }
//
//        let sheet = UIAlertController(title: "Conversation " + (name ?? "Chat"), message: nil, preferredStyle: .actionSheet)
//
//        sheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
//
//            let alert = UIAlertController(title: "Are you sure?", message: "The conversation \(name ?? "Chat") will be removed from your list, the messages will be kept and can be restored later.", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
//
//                FirebaseService.deleteChannel(channel: channel, fromCurrentUser: true)
//            }))
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//
//            UIViewController.topMostController().present(alert, animated: true, completion: nil)
//        }))
//        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        UIViewController.topMostController().present(sheet, animated: true, completion: nil)
    }
    
    override func didTap() {
        guard let channel = channel else { return }
        
        let vc = ChatViewController.instantiate(channel: channel)
        UIViewController.topMostController().presentModally(viewController: vc)
    }
    
}
