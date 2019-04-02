//
//  CreateNewChannelViewController.swift
//  Points4That
//
//  Created and Copyright © 2012-2018 Zappland Inc. All rights reserved.
//

import UIKit

class CreateNewChannelViewController: UIViewController, UITableViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    private let dataSource = TableViewDataSource()
    private var currentUser: FirebaseUser!
    
    private var selectedUsers : [FirebaseUser] {
        return currentUser.friends.filter({ $0.isSelected })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ContactTableViewCell", bundle: nil), forCellReuseIdentifier: "FirebaseUser")
        
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshContent()
    }
    
    func refreshContent() {
        
        self.currentUser?.stopObserving()
        if let currentUser = FirebaseUser.current {
            self.currentUser = currentUser
            currentUser.attachOnce { [weak self] in
                DispatchQueue.main.async {
                    
                    let users = currentUser.friends
                    if users.count > 0 {
                        self?.dataSource.items = users
                        self?.view?.hideEmptyDataset()
                    } else {
                        self?.dataSource.items = []
                        self?.view?.showEmptyDataset(title: "Oh, you have no Friends yet!", subtitle: "Add More Friends from your Contacts and start chatting!", buttonTitle: "Add a Friend", action: {
                            ContactService.shared.presentContactPicker(completion: { (contact) in
                                if let user = FirebaseUser.current {
                                    user.attachOnce {
                                        user.friends.append(contact)
                                        user.save()
                                    }
                                }
                            })
                        })
                    }
                    
                    for user in users {
                        user.isSelected = false
                        user.attachOnce {
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                    }
                    
                    self?.tableView.reloadData()
                }
            }// end of observations
        }// end if let
    }
    
    // ----------------------------------------------------
    // MARK: - UITableViewDelegate
    // ----------------------------------------------------
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let user = dataSource.items[indexPath.row] as! FirebaseUser
        user.isSelected = !user.isSelected
        
        tableView.reloadData()
    }
    
    // ----------------------------------------------------
    // MARK: - Actions
    // ----------------------------------------------------
    
    weak var createNewChannelTextField : UITextField?
    
    @IBAction func doneTapped(_ sender: Any) {
        
        switch selectedUsers.count {
        case 0:
            let _ = UIAlertController.presentOKAlertWithTitle("No Friends selected", message: "Please select some Friends.", okTapped: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            break
        case 1:
            // individual
            createIndividualChat()
        default:
            createGroupChat()
        }
        
    }
    
    private func createIndividualChat() {
        guard let user = selectedUsers.first else { return }
        
        let chatParticipantSetting = ChatParticipantSetting(otherUserKey: user.id, ofCurrentUser: false)
        chatParticipantSetting.attachOnce { [weak self] in
            DispatchQueue.main.async {
                if let channel = FirebaseService.createChannel(user: user, otherUserChatParticipantSetting: chatParticipantSetting) {
                    self?.navigateTo(channel: channel)
                }
            }
        }
        
    }
    
    private var createAction : UIAlertAction?
    private func createGroupChat() {
        
        let alert = UIAlertController(title: "Create New Chat", message: "", preferredStyle: .alert)
        alert.addTextField { [weak self] (textField : UITextField) in
            textField.placeholder = "Type the title of the chat"
            textField.delegate = self
            self?.createNewChannelTextField = textField
        }
        createAction = UIAlertAction(title: "Create", style: .default, handler: { [weak self] (action) in
            
            guard let name = self?.createNewChannelTextField?.text, let selectedUsers = self?.selectedUsers else { return; }
            
            //
            guard let current = FirebaseUser.current else { return }
            
            let participants = selectedUsers + [current]
            let channel = FirebaseService.createChannel(name: name, participants: participants)
            self?.navigateTo(channel: channel)
        })
        createAction?.isEnabled = false
        alert.addAction(createAction!)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        UIViewController.topMostController().present(alert, animated: true, completion: nil)
    }
    
    private func navigateTo(channel: Channel) {
        let vc = ChatViewController.instantiate(channel: channel)
        NavigationService.shared.presentModally(viewController: vc, animated: true, completion: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
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
