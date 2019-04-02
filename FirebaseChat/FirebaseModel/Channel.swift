//
//  Channel.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

class Channel : FirebaseModel {
    override class var basePath : String { return "channels" }
    
    override var skipProperties: [String] {
        return super.skipProperties + ["otherParticipants", "participantsString", "otherActiveParticipants", "otherParticipantSettings", "activeParticipants", "isOneOnOneChat", "otherOneOnOneParticipantId"]
    }
    
    // Mapped properties
    @objc var name: String?
    @objc var participants = [FirebaseUser]()
    @objc var lastMessageNested: ChatMessage?
    @objc var chatParticipantSettingsNested = [ChatParticipantSetting]()
    
    func setting(ofParticipant participant: FirebaseUser) -> ChatParticipantSetting {
        if let setting = chatParticipantSettingsNested.filter({ $0.id == participant.id }).first {
            return setting
        } else {
            let chatParticipantSetting = ChatParticipantSetting(channelKey: id, userKey: participant.id)
            chatParticipantSettingsNested.append(chatParticipantSetting)
            return chatParticipantSetting
        }
    }
    
    func currentUserSetting() -> ChatParticipantSetting? {
        guard let participant = FirebaseUser.current else { return nil }
        return setting(ofParticipant: participant)
    }
    var otherParticipantSettings : [ChatParticipantSetting] {
        return chatParticipantSettingsNested.filter({ $0.isCurrent() })
    }
    
    var isOneOnOneChat : Bool {
        return id.count > 32
    }
    
    var otherOneOnOneParticipantId : String? {
        if isOneOnOneChat, let user = FirebaseUser.current {
            return id.replacingOccurrences(of: user.id, with: "")
        } else {
            return nil
        }
    }
    
    // Ignored properties
    var otherParticipants : [FirebaseUser] {
        return participants.filter({ $0.isCurrent == false })
    }
    
    var otherActiveParticipants : [FirebaseUser] {
        // If the other participant hasn't left the conversation
        return otherParticipants.filter({ setting(ofParticipant: $0).chatParticipantRole != .left })
    }
    
    var activeParticipants : [FirebaseUser] {
        // If the other participant hasn't left the conversation
        return participants.filter({ setting(ofParticipant: $0).chatParticipantRole != .left })
    }
    
    var participantsString: String {
        return otherParticipants.compactMap({ (user) -> String? in
            return user.name
        }).joined(separator: ", ")
    }
    
    static func jointKey(userAId: String, userBId: String) -> String {
        return [userAId, userBId].sorted().joined(separator: "")
    }
    
    static func channel(userId: String) -> Channel? {
        
        guard let currentUser = FirebaseUser.current else { return nil }
        let currentUserKey = currentUser.id
        
        let key = jointKey(userAId: currentUserKey, userBId: userId)
        let channel = Channel()
        channel.id = key
        
        let user = FirebaseUser()
        user.id = userId
        channel.participants = [user, currentUser]
        
        return channel
    }
    
    func attachParticipants(with: (()->Void)? = nil) {
        let group = DispatchGroup()
        let otherParticipants = self.otherParticipants
        for participant in otherParticipants {
            group.enter()
            participant.attachOnce(with: {
                group.leave()
            })
        }
        group.notify(queue: DispatchQueue.main) {
            with?()
        }
    }
    
    func participant(userId: String) -> FirebaseUser? {
        return participants.filter({ $0.id == userId }).first
    }
    
    func name(ofParticipantId userId: String) -> String? {
        if let user = participant(userId: userId) {
            if user.isCurrent {
                return FirebaseUser.current?.name
            } else {
                return user.name
            }
        }
        return nil
    }
    
}
