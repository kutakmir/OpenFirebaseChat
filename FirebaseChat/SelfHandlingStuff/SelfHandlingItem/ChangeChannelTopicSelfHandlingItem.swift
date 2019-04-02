//
//  ChangeChannelTopicSelfHandlingItem.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class ChangeChannelTopicSelfHandlingItem: SelfHandlingItem, UITextFieldDelegate {
    
    let channel: Channel
    let chatParticipantSetting : ChatParticipantSetting
    private let completion: ((_ name: String)->Void)?
    
    // TODO: we can replace chatParticipantSetting with channel.currentUserSetting()?
    init(channel: Channel, chatParticipantSetting: ChatParticipantSetting, completion: ((_ name: String)->Void)? = nil) {
        self.channel = channel
        self.chatParticipantSetting = chatParticipantSetting
        self.completion = completion
        
        super.init()
        
        if chatParticipantSetting.chatParticipantRole == .admin {
            
            action = presentPopup
            title = "Change channel name"
        }
    }
    
    private var createAction : UIAlertAction?
    weak var createNewChannelTextField : UITextField?
    func presentPopup() {
        
        let alert = UIAlertController(title: "Change channel name", message: "", preferredStyle: .alert)
        alert.addTextField { [weak self] (textField : UITextField) in
            textField.placeholder = "Type the title of the chat"
            textField.delegate = self
            textField.text = self?.channel.name
            self?.createNewChannelTextField = textField
        }
        createAction = UIAlertAction(title: "Change", style: .default, handler: { [weak self] (action) in
            guard let name = self?.createNewChannelTextField?.text else { return }
            
            self?.channel.name = name
            self?.channel.save()
            
            self?.completion?(name)
        })
        createAction?.isEnabled = false
        alert.addAction(createAction!)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        UIViewController.topMostController().present(alert, animated: true, completion: nil)
    }
    
    // ----------------------------------------------------
    // MARK: - TextField Delegate
    // ----------------------------------------------------
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let finalText = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        
        if textField == createNewChannelTextField {
            
            if finalText.replacingOccurrences(of: " ", with: "").count == 0 {
                createAction?.isEnabled = false
            } else {
                createAction?.isEnabled = true
            }
        }
        
        return true
    }
}

