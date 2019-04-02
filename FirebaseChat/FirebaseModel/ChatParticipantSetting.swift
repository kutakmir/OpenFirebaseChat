//
//  ChatParticipantSetting.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit
import FirebaseDatabase

enum ChatParticipantRole : String {
    case member
    case admin
    case left
}

class ChatParticipantSetting: FirebaseModel {
    
    convenience init(otherUserKey: String, ofCurrentUser: Bool) {
        self.init()
        
        guard let currentUserKey = FirebaseUser.current?.id else { return }
        
        id = otherUserKey
        let channelKey = Channel.jointKey(userAId: otherUserKey, userBId: currentUserKey)
        reference = FirebaseService.readChannelRef(channelKey: channelKey, userKey: ofCurrentUser ? currentUserKey : otherUserKey)
    }
    
    convenience init(channelKey: String, userKey: String) {
        self.init()
        
        id = userKey
        reference = FirebaseService.readChannelRef(channelKey: channelKey, userKey: userKey)
    }
    
    required init() { super.init() }
    
    required init?(snapshot: DataSnapshot) {
        super.init(snapshot: snapshot)
    }
    
    required init(id: String) {
        super.init(id: id)
    }
    
    @objc var lastReadMessageDate : Date?
    
    override var skipProperties: [String] {
        return super.skipProperties + ["chatParticipantRole"]
    }
    
    @objc var hasUnreadMessages : Bool = false
    @objc var notificationsMuted : Bool = false
    @objc var conversationBlocked : Bool = false
    @objc var role : String?
    
    var chatParticipantRole : ChatParticipantRole {
        get {
            if let role = role {
                return ChatParticipantRole(rawValue: role) ?? .member
            } else {
                return .member
            }
        }
        set {
            role = newValue.rawValue
        }
    }
    
    func isCurrent() -> Bool {
        if let currentId = FirebaseUser.current?.id, currentId == id {
            return true
        }
        return false
    }
    
}
