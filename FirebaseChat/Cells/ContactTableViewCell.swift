//
//  ContactTableViewCell.swift
//  FirebaseChat
//
//  Created by Miroslav Kutak on 19/03/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import UIKit
import Contacts
import FirebaseDatabase


class ContactTableViewCell: UITableViewCell, Configurable {
    
    var contact: FirebaseUser?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var inviteButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
    }
    
    func configure(item: Any) {
        if let contact = item as? FirebaseUser {
            self.contact = contact
            configure(contact: contact)
        }
    }
    func configure(contact: FirebaseUser) {
        
        inviteButton?.isHidden = contact.exists
        
        nameLabel.text = " "
        contact.getDisplayName { [weak self] (name: String?) in
            DispatchQueue.main.async {
                self?.nameLabel.text = name
            }
        }
        
        if contact.isSelected {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }
    }
}
