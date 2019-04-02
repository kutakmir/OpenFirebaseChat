//
//  AddParticipantToChannelSelfHandlingItem.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class AddParticipantToChannelSelfHandlingItem: SelfHandlingItem {
    
    let channel: Channel
    private let completion: (()->Void)?
    
    init(channel: Channel, completion: (()->Void)? = nil) {
        self.channel = channel
        self.completion = completion
        
        super.init()
        
        action = {
            if let current = FirebaseUser.current {
                FirebaseUser.current?.attachOnce {
                    DispatchQueue.main.async {
                        
                        // TODO: add a Friends Picker delegate here
                        //       also, pass the completion handler
//                        let vc : FriendsPickerViewController = FriendsPickerViewController.instantiate()
//                        vc.delegate = self
//                        let friends = current.friends.filter({ channel.activeParticipants.contains($0) == false })
//                        vc.customFriends = friends
//
//                        NavigationService.shared.show(viewController: vc)
                    }
                }
            }
        }
        title = "Add person"
    }
}

