//
//  MessageUIExtension.swift
//  FirebaseChat
//
//  Created by Miroslav Kutak on 19/03/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

// TODO: refactor this into a SelfHandlingItem
//class MessageUIService : NSObject, MFMessageComposeViewControllerDelegate, UINavigationControllerDelegate {
//    
//    static let shared = MessageUIService()
//    private override init() {}
//    
//    func show(text: String?, recipients: [FirebaseUser]) {
//        
//        if MFMessageComposeViewController.canSendText() == false {
//            return
//        }
//        
//        var recipientPhoneNumbers = [String]()
//        for recipient in recipients {
//            if let contact = ContactService.shared.contact(forUser: recipient), let phone = contact.standardizedPhoneNumbers().first {
//                recipientPhoneNumbers.append(phone)
//            }
//        }
//        
//        let composer = MFMessageComposeViewController()
//        composer.body = text
//        composer.recipients = recipientPhoneNumbers
//        composer.messageComposeDelegate = self
//        UIViewController.topMostController().present(composer, animated: true, completion: nil)
//    }
//
//    // ----------------------------------------------------
//    // MARK: - MFMessageComposeViewControllerDelegate
//    // ----------------------------------------------------
//    
//    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
//        switch result {
//        case .sent, .cancelled:
//            controller.dismiss(animated: true, completion: nil)
//        default:
//            break
//        }
//    }
//    
//    
//    func inviteOrProcessRequest(user: FirebaseUser) {
//        let nickNameFriend = user.name ?? ""
//        
//        if user.friendStatus.shouldInvite {
//            
//            invite(user: user)
//        } else if user.friendStatus == .request {
//            
//            let alert = UIAlertController(title: "Become friends with \(nickNameFriend)?", message: "\(nickNameFriend) has invited you to be their friend.", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { (action: UIAlertAction) in
//                FirebaseService.addAFriend(friend: user)
//            }))
//            alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: nil))
//            UIViewController.topMostController().present(alert, animated: true, completion: nil)
//        }
//    }
//    
//    func askToInvite(user: FirebaseUser) {
//        let nickNameFriend = user.name ?? ""
//        let alert = UIAlertController(title: "Invite \(nickNameFriend) to play?", message: nil, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Invite", style: .default, handler: { [weak self] (action: UIAlertAction) in
//            
//            self?.invite(user: user)
//        }))
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        UIViewController.topMostController().present(alert, animated: true, completion: nil)
//    }
//    
//    func invite(user: FirebaseUser) {
//        let nickNameFriend = user.name ?? ""
//        switch user.friendStatus {
//        case .pending:
//            let inviteText = "Hi, \(nickNameFriend), I added you in Points4That, add me! https://points4that.app.link/O6EN64xFBL"
//            MessageUIService.shared.show(text: inviteText, recipients: [user])
//        case .notConnected:
//            FirebaseService.addAFriend(friend: user)
//        case .nonUser:
//            let inviteText = "Hi, \(nickNameFriend), play Points4that with me! Get the app here: https://points4that.app.link/O6EN64xFBL"
//            MessageUIService.shared.show(text: inviteText, recipients: [user])
//        default:
//            break
//        }
//    }
//    
//    
//}
