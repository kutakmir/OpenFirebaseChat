/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import Photos
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import JSQMessagesViewController
import JSQSystemSoundPlayer
import OneSignal

final class ChatViewController: JSQMessagesViewController, PointsSelectionDelegate {
    
    var bottomContentAdditionalInset : CGFloat = 0.0
    
    static func instantiate(channel: Channel) -> ChatViewController {
        let vc = ChatViewController()
        
        vc.senderDisplayName = FirebaseUser.current?.name
        vc.channel = channel
        vc.channelRef = vc.channel?.ref
        vc.title = channel.name ?? channel.participantsString
        
        channel.observePropertyAndKeepAttached(property: "chatParticipantSettingsNested") { [weak vc] in
            DispatchQueue.main.async {
                vc?.refreshChatSettingsBarButtonItem()
            }
        }
        
        return vc
    }
    
    // MARK: Properties
    private let imageURLNotSetKey = "NOTSET"
    
    var channelRef: DatabaseReference?
    
    private var latestMessagesQuery: DatabaseQuery?
    private lazy var messageRef: DatabaseReference = ChatMessage.baseRef.child(self.channel!.id)
    fileprivate lazy var storageRef: StorageReference = Storage.storage().reference(forURL: "gs://p4tdevbz171108.appspot.com")
    private lazy var userIsTypingRef: DatabaseReference = self.channelRef!.child("typingIndicator").child(self.senderId)
    private lazy var usersTypingQuery: DatabaseQuery = self.channelRef!.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    private lazy var readChannelRef: DatabaseReference = self.channelRef!.child("chatParticipantSettingsNested")
    private lazy var userHasReadChannelRef: DatabaseReference = self.channelRef!.child("chatParticipantSettingsNested").child(self.senderId)
    
    private var newMessageRefHandle: DatabaseHandle?
    private var updatedMessageRefHandle: DatabaseHandle?
    
    private var messages: [JSQMessage] = []
    private var chatMessages: [ChatMessage] = []
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    
    private let plusMinusButtonsViewController = PlusMinusButtonsViewController(nibName: nil, bundle: nil)
    
    private let pageSize : Int = 15
    private var localTyping = false
    var channel: Channel?
    var points: Points?
    
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    var timer : Timer?
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        senderId = FirebaseService.currentUserKey
        
        if let chatMessage = channel?.lastMessageNested {
            appendMessage(chatMessage: chatMessage, atStart: true)
        }
        loadOlderMessages { [weak self] in
            self?.finishReceivingMessage(animated: false)
            self?.observeMessages()
        }
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        
        plusMinusButtonsViewController.delegate = self
        inputToolbar.contentView.leftBarButtonItem = nil
    }
    
    func configure(points: Points) {
        // TODO: point mentions
    }
    
    func refreshChatSettingsBarButtonItem() {
        
        if let channel = channel, let chatParticipantSetting = channel.currentUserSetting() {
            
            let changeChannelTopicItem = ChangeChannelTopicSelfHandlingItem(channel: channel, chatParticipantSetting: chatParticipantSetting, completion: { [weak self] name in
                self?.title = name
            })
            let muteUnmuteItem = MuteOrUnmuteChannelSelfHandlingItem(channel: channel)
            
            let friendsListItem = SelfHandlingItem(title: "Show Participants", action: {
                DispatchQueue.main.async {
                    let vc : ChannelParticipantsViewController = ChannelParticipantsViewController.instantiate()
                    vc.channel = channel
                    NavigationService.shared.show(viewController: vc, animated: true)
                }
            })
            
            let leaveChannelItem = LeaveChannelSelfHandlingItem(channel: channel, completion: {
                
                // Navigate back to the root VC (the current user should not be able to see the channel anymore (because they have left)
                NavigationService.shared.unwindToRoot(animated: true, completion: {
                    
                })
            })
            
            let addParticipantItem = AddParticipantToChannelSelfHandlingItem(channel: channel)
            let reportItem = ReportSelfHandlingItem(reportedChannel: channel)
            
            
            if chatParticipantSetting.chatParticipantRole == .admin {
                
                
                navigationItem.rightBarButtonItem = SettingsBarButtonItem(options: [
                    addParticipantItem,
                    changeChannelTopicItem,
                    friendsListItem,
                    muteUnmuteItem,
                    leaveChannelItem,
                    reportItem
                    ])
            } else {
                navigationItem.rightBarButtonItem = SettingsBarButtonItem(options: [
                    muteUnmuteItem,
                    leaveChannelItem,
                    reportItem
                    ])
            }
        }
    }
    
    
    func attachPointsToolbar() {
        
        if let view = plusMinusButtonsViewController.view {
            view.attach(aboveView: inputToolbar)
            bottomContentAdditionalInset = view.frame.size.height
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        attachPointsToolbar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        observeTyping()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { [weak self] in
            self?.shouldStartMarkingMessagesAsRead = true
            self?.shouldScrollToBottom = false
            self?.readTheMessages()
        }
        
        inputToolbar.contentView.textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        inputToolbar.contentView.textView.resignFirstResponder()
    }
    
    // ----------------------------------------------------
    // MARK: - UITextViewDelegate
    // ----------------------------------------------------
    
    private var selectedTextView: UITextView?
    override func textViewDidChangeSelection(_ textView: UITextView) {
        selectedTextView = textView
    }
    
    deinit {
        // Stop observing
        if let refHandle = newMessageRefHandle {
            latestMessagesQuery?.removeObserver(withHandle: refHandle)
        }
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }
    
    // MARK: Collection view data source (and related) methods
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let chatMessage = chatMessages[indexPath.item]
        
        if chatMessage.isIncoming {
            return incomingBubbleImageView
        } else {
            return outgoingBubbleImageView
        }
    }
    
    func lastPositiveMessage(indexPath: IndexPath) -> Bool? {
        
        for i in (0...indexPath.item).reversed() {
            let message = messages[i]
            
            if message.text.hasPrefix("+") {
                return true
            }
            if message.text.hasPrefix("-") {
                return false
            }
        }
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        cell.textView?.delegate = self
        
        let message = messages[indexPath.item]
        let chatMessage = chatMessages[indexPath.item]
        
        if chatMessage.containsPoints {
            cell.textView?.textColor = UIColor.white
        } else {
            if message.senderId == senderId { // 1
                cell.textView?.textColor = UIColor.white // 2
            } else {
                cell.textView?.textColor = UIColor.black // 3
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView?, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString? {
        let message = messages[indexPath.item]
        let chatMessage = chatMessages[indexPath.item]
        
        
        if let creatorId = chatMessage.creatorId, let channel = channel, let sender = channel.participant(userId: creatorId) {
            if sender.isCurrent() {
                return nil
            } else {
                if let name = sender.name {
                    return NSAttributedString(string: (name))
                } else {
                    return NSAttributedString(string: ("zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"))
                }
                
            }
        }
        
        switch message.senderId {
        case senderId:
            return nil
        default:
            guard let senderDisplayName = message.senderDisplayName else {
                assertionFailure()
                return nil
            }
            return NSAttributedString(string: senderDisplayName)
        }
    }
    
    
    private var isLoadingOlderMessages = false
    private var hasLoadedAllOlderMessages = false
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //super.scrollViewDidScroll(scrollView)
        
        if scrollView.contentOffset.y < 300.0 && isLoadingOlderMessages == false && hasLoadedAllOlderMessages == false {
            loadOlderMessages(completion: {})
        }
    }
    
    
    // MARK: Firebase related methods
    private var shouldScrollToBottom = true
    private var shouldStartMarkingMessagesAsRead = false
    private func readTheMessages() {
        // Read the message
        if let lastMessageDate = self.messages.last?.date, shouldStartMarkingMessagesAsRead {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = FirebaseModel.Format.dateFormat
            let dateString = dateFormatter.string(from: lastMessageDate)
            
            userHasReadChannelRef.child("lastReadMessageDate").setValue(dateString)
        }
        
        userHasReadChannelRef.child(#keyPath(ChatParticipantSetting.hasUnreadMessages)).setValue(false)
    }
    
    private func observeMessages() {
        // We can use the observe method to listen for new
        // messages being written to the Firebase DB
        
        if let firstMessageId = chatMessages.last?.id {
            latestMessagesQuery = messageRef.queryOrderedByKey().queryEnding(atValue: firstMessageId)
        } else {
            latestMessagesQuery = messageRef.queryOrderedByKey()
        }
        
        newMessageRefHandle = latestMessagesQuery?.observe(.childAdded, with: { [weak self] (snapshot) -> Void in
            DispatchQueue.main.async {
                if self?.chatMessages.last?.id != snapshot.key {
                    self?.appendMessage(snapshot: snapshot, atStart: false)
                }
            }
        })
        
        // We can also use the observer method to listen for
        // changes to existing messages.
        // We use this to be notified when a photo has been stored
        // to the Firebase Storage, so we can update the message data
        updatedMessageRefHandle = messageRef.observe(.childChanged, with: { [weak self] (snapshot) in
            let key = snapshot.key
            let messageData = snapshot.value as! Dictionary<String, String>
            
            if let photoURL = messageData["photoURL"] {
                // The photo has been updated.
                if let mediaItem = self?.photoMessageMap[key] {
                    self?.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key)
                }
            }
        })
    }
    
    func loadOlderMessages(completion: @escaping ()->Void) {
        
        var query : DatabaseQuery? = messageRef.queryOrderedByKey().queryLimited(toFirst: UInt(pageSize))
        var isLoadingFirstPage = true
        
        if let oldestMessage = chatMessages.first {
            
            query = messageRef.queryOrderedByKey().queryStarting(atValue: oldestMessage.id).queryLimited(toFirst: UInt(pageSize))
//            return
            isLoadingFirstPage = false
            
        }
        
        isLoadingOlderMessages = true
        query?.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            DispatchQueue.main.async {
                
                var i = 0
                var children = snapshot.children.allObjects as! [DataSnapshot]
                if isLoadingFirstPage {
                    children = children.reversed()
                }
                for child in children {
                    
                    // Skip the first one (it's the same as the oldest message)
                    if i == 0 && isLoadingFirstPage == false {
                        i += 1
                        continue
                    }
                    
                    // Insert at the beginning
                    self?.appendMessage(snapshot: child, atStart: !isLoadingFirstPage)
                    
                    i += 1
                }
            
                if children.count == self?.pageSize {
                    // everything ok, regular batch
                } else {
                    // We have reached the end of the conversation
                    self?.hasLoadedAllOlderMessages = true
                }
                
                self?.isLoadingOlderMessages = false
                
                completion()
            }
        })
    }
    
    
    fileprivate func appendMessage(snapshot: DataSnapshot, atStart: Bool) {
        guard let chatMessage = ChatMessage(snapshot: snapshot) else { return }
        appendMessage(chatMessage: chatMessage, atStart: atStart)
    }
    
    fileprivate func appendMessage(chatMessage: ChatMessage, atStart: Bool) {
        
        var message : JSQMessage?
        
        // POINTS MESSAGE
        if let points = chatMessage.points, let senderId = chatMessage.senderId {
            var toNickname : String?
            if let recipientId = chatMessage.recipientId {
                toNickname = channel?.name(ofParticipantId: recipientId)
            }
            let fromNickname = channel?.name(ofParticipantId: senderId)
            
            let mediaItem = JSQPoints4ThatItem(points: points, chatMessage: chatMessage, fromNickname: fromNickname, toNickname: toNickname)
            message = JSQMessage(senderId: senderId, displayName: "", media: mediaItem)
            
        } else
            // CHAT MESSAGE
        if let id = chatMessage.senderId, let text = chatMessage.text, text.count > 0, let channel = channel, let user = channel.participant(userId: id) {
            var name = ""
            if chatMessage.isIncoming {
                name = user.name ?? ""
            } else {
                name = senderDisplayName ?? ""
            }
            
            message = JSQMessage(senderId: id, displayName: name, text: text)
        } else
            // PHOTO MESSAGE
        if let id = chatMessage.senderId, let photoURL = chatMessage.photoURL {
            if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == senderId) {
                message = JSQMessage(senderId: id, displayName: "", media: mediaItem)
                
                if (mediaItem.image == nil) {
                    photoMessageMap[chatMessage.id] = mediaItem
                }
                
                if photoURL.hasPrefix("gs://") {
                    fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                }
            }
        } else {
            print("Error! Could not decode message data")
        }
        
        if let message = message {
            
            if atStart {
                messages.insert(message, at: 0)
                chatMessages.insert(chatMessage, at: 0)
            } else {
                messages.append(message)
                chatMessages.append(chatMessage)
            }
            collectionView.reloadData()
        }
        
        // Scroll down
        if isLoadingOlderMessages == false {
            finishReceivingMessage(animated: true)
        }
        
        // Read all the messages
        readTheMessages()
        
        // Scroll
        if shouldScrollToBottom {
            scrollToBottom(animated: false)
        }
    }
    
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        let storageRef = Storage.storage().reference(forURL: photoURL)
        storageRef.getData(maxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            storageRef.getMetadata(completion: { [weak self] (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    
                    //                if (metadata?.contentType == "image/gif") {
                    //                    mediaItem.image = UIImage.gifWithData(data!)
                    //                } else {
                    mediaItem.image = UIImage.init(data: data!)
                    //                }
                    self?.collectionView.reloadData()
                    
                    guard key != nil else {
                        return
                    }
                    self?.photoMessageMap.removeValue(forKey: key!)
                }
            })
        }
    }
    
    private func observeTyping() {
        let typingIndicatorRef = channelRef!.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqual(toValue: true)
        
        usersTypingQuery.observe(.value) { [weak self] (data: DataSnapshot) in
            
            DispatchQueue.main.async {
                
                guard let _self = self else { return }
                
                // You're the only typing, don't show the indicator
                if data.childrenCount == 1 && _self.isTyping {
                    return
                }
                
                // Are there others typing?
                self?.showTypingIndicator = data.childrenCount > 0
                self?.scrollToBottom(animated: true)
            }
        }
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        guard let text = text, let channel = channel else { return }
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        isTyping = false
        
        if messages.count == 0 {
            // The first message
        }
        
        if channel.otherParticipants.count == 1, let user = channel.otherParticipants.first {
            let otherUserChatParticipantSetting = channel.setting(ofParticipant: user)
        
            // Create a channel
            let _ = FirebaseService.createChannel(user: user, createForCurrentUser: true, createForOtherUser: true, otherUserChatParticipantSetting: otherUserChatParticipantSetting)
            // Create a message
            FirebaseService.sendMessage(text: text, channel: channel, user: user)
        } else {
            // Create a message
            FirebaseService.sendMessage(text: text, channel: channel)
        }
        
        // Push notification
        for participant in channel.otherParticipants {
            FirebaseService.sendMessageNotification(text: text, channel: channel, user: participant)
        }
    }
    
    
    
    func sendPhotoMessage() -> String? {
        let itemRef = messageRef.childByAutoId()
        
        let messageItem = [
            "photoURL": imageURLNotSetKey,
            "senderId": senderId!,
            ]
        
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        return itemRef.key
    }
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = messageRef.child(key)
        itemRef.updateChildValues(["photoURL": url])
    }
    
    // MARK: UI and User Interaction
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        
        ImagePicker.shared.pickImage(self) { [weak self] (imageFileURL, photoReferenceUrl) in
            
            if let key = self?.sendPhotoMessage() {
                let path = "\(Firebase.auth().currentUser?.uid ?? "")/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(photoReferenceUrl.lastPathComponent)"
                self?.storageRef.child(path).putFile(from: imageFileURL, metadata: nil) { (metadata, error) in
                    if let error = error {
                        print("Error uploading photo: \(error.localizedDescription)")
                        return
                    }
                    self?.setImageURL(self?.storageRef.child((metadata?.path)!).description ?? "", forPhotoMessageWithKey: key)
                }
            }
        }
        
    }
    
    // MARK: UITextViewDelegate methods
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    override func isOutgoingMessage(_ messageItem: JSQMessageData!) -> Bool {
        let index = messages.index(of: messageItem as! JSQMessage)
        let chatMessage = chatMessages[index!]
        return !chatMessage.isIncoming
    }
    
    override func jsq_updateCollectionViewInsets() {
        jsq_setCollectionViewInsetsTopValue(topLayoutGuide.length + topContentAdditionalInset, bottomValue: CGRectGetMaxY(collectionView.frame) - CGRectGetMinY(inputToolbar.frame) + bottomContentAdditionalInset)
    }
    
    // ----------------------------------------------------
    // MARK: - PointsSelectionDelegate
    // ----------------------------------------------------
    
    func pointsSelected(positive: Bool) {
        
        let vc : OneMasterPlusAndMinusViewController = OneMasterPlusAndMinusViewController.instantiate()
        vc.hasLoaded = true
        vc.isPresentedModally = true
        vc.shouldHidePointsPostsSegmentedController = true
        vc.customFriends = channel?.otherParticipants
        if let otherParticipants = channel?.otherParticipants, otherParticipants.count == 1, let user = otherParticipants.first {
            vc.user = user
        }
        vc.channel = channel
        vc.points = Points()
        vc.points.positive = positive
        vc.transition(toState: positive ? .positive : .negative, animated: false)
        vc.shouldDisplayAConfirmationPopupAfterGivingPoints = false
        
        NavigationService.shared.presentModally(viewController: vc, animated: true, completion: nil)
    }
    
}

func CGRectGetMinY(_ rect: CGRect) -> CGFloat {
    return rect.origin.y
}

func CGRectGetMaxY(_ rect: CGRect) -> CGFloat {
    return rect.size.height + rect.origin.y
}
