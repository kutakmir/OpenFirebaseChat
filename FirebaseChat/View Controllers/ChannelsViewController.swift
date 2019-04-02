//
//  ChannelsViewController.swift
//  Points4That
//
//  Created and Copyright © 2012-2018 Zappland Inc. All rights reserved.
//

import UIKit

class ChannelsTableViewDataSource: TableViewDataSource {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = super.tableView(tableView, numberOfRowsInSection: section)
        
        if count > 0 {
            tableView.superview?.hideEmptyDataset()
        } else {
            guard let currentUser = FirebaseUser.current else { return count }
            
            if currentUser.friends.count > 0 {
                tableView.superview?.showEmptyDataset(title: "Oh, you have no Chats yet!", subtitle: "", buttonTitle: "Start a Chat", action: {
                    DispatchQueue.main.async {
                        UIViewController.topMostController().performSegue(withIdentifier: "showCreateNewChatVC", sender: nil)
                    }
                })
            } else {
                tableView.superview?.showEmptyDataset(title: "Oh, you have no friends yet!", subtitle: "Add more friends from your contacts and start chatting!", buttonTitle: "Add a Friend", action: {
                    ContactService.shared.presentContactPicker(completion: { (user) in
                    })
                })
            }
        }
        return count
    }
}

class ChannelsViewController: UIViewController {
    
    private var data: UserData!
    private var dataSource = ChannelsTableViewDataSource()
    
    @IBOutlet weak var tableView: UITableView?
    private var channels = [Channel]()
    private var pointsChannels = [Channel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView?.delegate = dataSource
        tableView?.dataSource = dataSource
        tableView?.tableFooterView = UIView()
        
        FirebaseUser.current?.attachOnce { [weak self] in
            DispatchQueue.main.async {
                self?.updateDataItems()
            }
        }
        
        data = FirebaseUser.current?.userData
        data.observePropertyAndKeepAttached(property: #keyPath(UserData.channels)) { [weak self] in
            DispatchQueue.main.async {
                let channels : [Channel] = self?.data.channels ?? []
                
                for channel in channels {
                    channel.observeAndKeepAttached {
                        DispatchQueue.main.async {
                            self?.updateDataItems()
                        }
                    }
                }
                
                self?.channels = channels
                self?.updateDataItems()
            }
        }
        
        data.observePropertyAndKeepAttached(property: #keyPath(UserData.pointsChannels)) { [weak self] in
            DispatchQueue.main.async {
                self?.pointsChannels = self?.data.pointsChannels ?? []
                self?.updateDataItems()
            }
        }
        
    }
    
    
    func updateDataItems() {
        
        let filteredChannels = channels.filter({ (channel: Channel) -> Bool in
            // Do not include 1-on-1 chats that are between the current user and somebody who is not a friend
            if let other1on1ID = channel.otherOneOnOneParticipantId {
                return FirebaseUser.current?.isFriend(friend: FirebaseUser(id: other1on1ID)) ?? false
            } else {
                return true
            }
        })
        
        dataSource.items = filteredChannels
        tableView?.reloadData()
        
        // UNCOMMENT FEATURE: Points Channels
//        guard let currentUser = FirebaseUser.current else { return }
//
//        let pChannels = (pointsChannels.count > 0 && currentUser.friends.count > 0) ? [Channel.pointsChannel] : []
//        dataSource.items = pChannels + channels
//        tableView?.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateDataItems()
    }
    
}
