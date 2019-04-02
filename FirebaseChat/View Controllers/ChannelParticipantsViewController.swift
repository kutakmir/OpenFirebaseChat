//
//  ChannelParticipantsViewController.swift
//  Points4That
//
//  Created and Copyright © 2012-2018 Zappland Inc. All rights reserved.
//

import UIKit

class ChannelParticipantsViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var channel: Channel!
    private var currentUser: FirebaseUser?
    
    var dataSource : ChannelParticipantsTableViewDataSource!
    var customFriends : [FirebaseUser]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = ChannelParticipantsTableViewDataSource(tableView: tableView, channel: channel)
        tableView.tableFooterView = UIView()
    }
    
    
}
