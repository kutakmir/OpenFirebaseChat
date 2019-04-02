//
//  FirebaseService+Chat.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase
import OneSignal

extension FirebaseService {
    
    static func leaveChannel(_ channel: Channel) {
        if let current = FirebaseUser.current {
            removeParticipant(participant: current, fromChannel: channel)
        }
    }
    
    static func createChannel(user: FirebaseUser, createForCurrentUser: Bool = false, createForOtherUser: Bool = false, otherUserChatParticipantSetting: ChatParticipantSetting) -> Channel? {
        
        let userId = user.id
        guard let currentUserKey = currentUserKey else { return nil }
        
        let channel = Channel()
        channel.id = Channel.jointKey(userAId: currentUserKey, userBId: userId)
        channel.reference = Channel.baseRef.child(channel.id)
        channel.participants = [FirebaseUser.current!, user]
        
        channel.save()
        
        // Current user's chat
        if createForCurrentUser {
            let currentUserChannelReference = UserData.baseRef.child(currentUserKey).child("channels").child(channel.id)
            currentUserChannelReference.setValue(0)
        }
        
        // Other user's chat
        if createForOtherUser && otherUserChatParticipantSetting.conversationBlocked == false {
            let otherUserChannelReference = UserData.baseRef.child(userId).child("channels").child(channel.id)
            otherUserChannelReference.setValue(0)
        }
        
        return channel
    }
    
    static func createChannel(name: String, participants: [FirebaseUser]) -> Channel {
        let channel = Channel()
        channel.participants = participants
        channel.name = name
        
        createChannel(channel)
        return channel
    }
    
    
    static func addChannelToItsParticipantsLists(channel: Channel) {
        
        // Current user's chat
        for participant in channel.participants {
            
            let channelReference = UserData.baseRef.child(participant.id).child("channels").child(channel.id)
            channelReference.setValue(0)
        }
    }
    
    static func createChannel(_ channel: Channel) {
        
        channel.save()
        
        addChannelToItsParticipantsLists(channel: channel)
        
        // Set the current user as an Admin
        let setting = ChatParticipantSetting(channelKey: channel.id, userKey: FirebaseUser.current!.id)
        setting.chatParticipantRole = .admin
        setting.save()
    }
    
    static func deleteChannel(channel: Channel, fromCurrentUser: Bool = false, fromOtherUsers: Bool = false) {
        
        let channelKey = channel.id
        guard let currentUser = FirebaseUser.current else { return }
        let currentUserKey = currentUser.id
        
        if fromCurrentUser {
            UserData.baseRef.child(currentUserKey).child("channels").child(channelKey).removeValue()
        }
        if fromOtherUsers {
            for participant in channel.participants {
                
                let userId = participant.id
                if participant.isCurrent == false {
                    UserData.baseRef.child(userId).child("channels").child(channelKey).removeValue()
                }
            }
        }
        
        // Remove the participant
        channel.ref.child("participants").child(currentUserKey).removeValue()
    }
    
    static func addParticipant(participant: FirebaseUser, toChannel channel: Channel) {
        
        channel.participants.append(participant)
        channel.save()
        
        let setting = channel.setting(ofParticipant: participant)
        setting.chatParticipantRole = .member
        setting.save()
        
        let channelReference = UserData.baseRef.child(participant.id).child("channels").child(channel.id)
        channelReference.setValue(0)
    }
    
    static func removeParticipant(participant: FirebaseUser, fromChannel channel: Channel) {
        
        let setting = channel.setting(ofParticipant: participant)
        // Leave channel
        setting.chatParticipantRole = .left
        setting.save()
        
        // Remove from the current user
        UserData.baseRef.child(participant.id).child("channels").child(channel.id).removeValue()
        
        // TODO: What if the admin leaves?
    }
    
    static func makeAdminFromParticipant(participant: FirebaseUser, inChannel channel: Channel) {
        let setting = channel.setting(ofParticipant: participant)
        // Leave channel
        setting.chatParticipantRole = .admin
        setting.save()
    }
    
    static func sendMessage(text: String, channel: Channel, user: FirebaseUser? = nil, fromOtherUser: Bool = false) {
        guard let currentUser = FirebaseUser.current, channel.activeParticipants.contains(currentUser) else {
            return
        }
        
        let channelRef = channel.ref
        let messageRef = ChatMessage.baseRef.child(channel.id)
        let senderId = fromOtherUser ? user!.id : currentUser.id
        let readChannelRef: DatabaseReference = channelRef.child(#keyPath(Channel.chatParticipantSettingsNested))
        
        let message = ChatMessage()
        message.senderId = senderId
        if let user = user {
            message.recipientId = fromOtherUser ? currentUser.id : user.id
        }
        message.text = text
        
        // Send message
        let itemRef = messageRef.child(message.id)
        itemRef.setValue(message.attributesDictionary())
        
        // Set an unread flag
        for participant in channel.otherActiveParticipants {
            readChannelRef.child(participant.id).child(#keyPath(ChatParticipantSetting.hasUnreadMessages)).setValue(true)
        }
        // Set the unread chat tab
        if let user = user {
            UserData.baseRef.child(user.id).child(#keyPath(UserData.userFlags)).child(#keyPath(UserFlags.unreadChatsTab)).setValue(true)
        }
        
        // Set last message
        channelRef.child(#keyPath(Channel.lastMessageNested)).setValue(message.dictionary())
    }
}
