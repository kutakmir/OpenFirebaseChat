//
//  ChatParticipantTableViewCell.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

/*
 A way how to pass channel and participant
 */
struct ChannelAndParticipant {
    let participant: FirebaseUser
    let channel: Channel
}

class ChatParticipantTableViewCell: UITableViewCell, Configurable {
    
    var contact: FirebaseUser?
    var channel: Channel?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func configure(item: Any) {
        if let channelAndParticipant = item as? ChannelAndParticipant {
            self.contact = channelAndParticipant.participant
            self.channel = channelAndParticipant.channel
            configure(participant: channelAndParticipant.participant, channel: channelAndParticipant.channel)
        }
    }
    
    func configure(participant: FirebaseUser, channel: Channel) {
        nameLabel.text = " "
        roleLabel.text = " "
        participant.getDisplayName { [weak self] (name: String?) in
            DispatchQueue.main.async {
                self?.nameLabel.text = name
                
                let setting = channel.setting(ofParticipant: participant)
                if setting.chatParticipantRole == .admin {
                    self?.roleLabel.text = "(Admin)"
                }
            }
        }
        
        if participant.isSelected {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }
    }
    

}
