//
//  ChannelParticipantsTableViewDataSource.swift
//  Points4That
//
//  Created and Copyright © 2012-2018 Zappland Inc. All rights reserved.
//

import UIKit

class ChannelParticipantsTableViewDataSource: TableViewDataSource {
    
    let channel: Channel
    
    init(tableView: UITableView, channel: Channel) {
        self.channel = channel
        super.init()
        self.tableView = tableView
        tableView.register(UINib(nibName: "ChatParticipantTableViewCell", bundle: nil), forCellReuseIdentifier: "ChannelAndParticipant")
        tableView.dataSource = self
        tableView.delegate = self
        
        items = channelAndActiveParticipants()
        tableView.reloadData()
    }
    
    func channelAndActiveParticipants() -> [ChannelAndParticipant] {
        var channelAndActiveParticipants = [ChannelAndParticipant]()
        let activeParticipants = channel.activeParticipants
        for participant in activeParticipants {
            channelAndActiveParticipants.append(ChannelAndParticipant(participant: participant, channel: channel))
        }
        return channelAndActiveParticipants
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let channelAndParticipant = self.items[indexPath.row] as! ChannelAndParticipant
        
        return [
            UITableViewRowAction(style: .destructive, title: "Delete", handler: { (action: UITableViewRowAction, indexPath: IndexPath) in
                
                tableView.beginUpdates()
                self.items.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.endUpdates()
                
                FirebaseService.removeParticipant(participant: channelAndParticipant.participant, fromChannel: self.channel)
            })
        ]
        
    }
    
}
