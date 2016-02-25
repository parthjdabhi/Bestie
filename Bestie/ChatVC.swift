//
//  ChatVC.swift
//  Bestie
//
//  Created by Nicholas Naudé on 15/02/2016.
//  Copyright © 2016 Nicholas Naudé. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController

class ChatVC: JSQMessagesViewController {
    
    
    // MARK: Chat Variables
    //var messageRef: Firebase! //change to actual ref pointing to messages/currentChat.chatID
    var messageClass = [Message]()
    var messages = [JSQMessage]()
    //    var userIsTypingRef: Firebase! //change to actual ref pointing to current chat objects is typing in DB
    //        var usersTypingQuery: FQuery!
    //        private var localTyping = false
    //        var isTyping: Bool {
    //            get {
    //                return localTyping
    //            }
    //            set {
    //                localTyping = newValue
    //                userIsTypingRef.setValue(newValue)
    //            }
    //        }
    
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    // MARK: Other Variables
    let defaults = NSUserDefaults.standardUserDefaults()
    var ref = Firebase(url: "https://bestieapp.firebaseio.com")
    var selectedChatUserId: String!
    var pathId = String()
    
    // MARK: Lifecycle Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBubbles()
        
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
    }
    
    override func viewWillAppear(animated: Bool) {
        ref.childByAppendingPath("/chat")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        joinOrCreateChat( { ()->() in
            self.observeMessages()
            
        })
        
    }
    
    // MARK: Action Functions
    @IBAction func onRevokeButtonTapped(sender: UIBarButtonItem) {
        
        signupErrorAlert("🤔", message: "Taking away their Princess Point removes them from your feed forever. Are you sure?")
        
    }
    
    
    //------------------------------------------------------------------------------------------------------------------------------------------
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        let currentUserId = defaults.valueForKey("User ID") as! String
        if message.senderId == currentUserId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        let currentUserId = defaults.valueForKey("User ID") as! String
        if message.senderId == currentUserId { // 1
            cell.textView!.textColor = UIColor.whiteColor() // 2
        } else {
            cell.textView!.textColor = UIColor.blackColor() // 3
        }
        
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    func addMessage(id: String, text: String) {
        let message = JSQMessage(senderId: id, displayName: "timmy", text: text)
        messages.append(message)
        
    }
    
    private func observeMessages() {
        let chatRef = ref.childByAppendingPath("chats")
        let messageQuery = chatRef.childByAppendingPath(self.pathId)
        messageQuery.queryLimitedToLast(100).observeEventType(.ChildAdded, withBlock: { snapshot in
                let text = snapshot.value!["messageContent"] as! String
                let id = snapshot.value!["senderId"] as! String
                
                self.addMessage(id, text: text)
            self.finishReceivingMessage()
        })
    }
    
    //    private func observeTyping() {
    //        let typingIndicatorRef = ref.childByAppendingPath("typingIndicator")
    //        userIsTypingRef = typingIndicatorRef.childByAppendingPath(senderId)
    //        userIsTypingRef.onDisconnectRemoveValue()
    //        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqualToValue(true)
    //
    //        usersTypingQuery.observeEventType(.Value) { (data: FDataSnapshot!) in
    //
    //            // You're the only typing, don't show the indicator
    //            if data.childrenCount == 1 && self.isTyping {
    //                return
    //            }
    //
    //            // Are there others typing?
    //            self.showTypingIndicator = data.childrenCount > 0
    //            self.scrollToBottomAnimated(true)
    //        }
    //    }
    
  
    
    //    override func textViewDidChange(textView: UITextView) {
    //        super.textViewDidChange(textView)
    //        // If the text is not empty, the user is typing
    //        isTyping = textView.text != ""
    //    }
    
    func joinOrCreateChat(completionHandler:() -> ()) {
        let currentUserUID = defaults.valueForKey("User ID") as? String ?? "i don't know"
        
        let desiredIdCombo = currentUserUID + selectedChatUserId
        let testIdCombo = selectedChatUserId + currentUserUID
        let chatRef = ref.childByAppendingPath("chats")
        var foundChat = false
        
        chatRef.queryOrderedByKey().observeSingleEventOfType(.Value, withBlock: { snapshot in
            print(snapshot.children.allObjects.count)
            for id in snapshot.children.allObjects {
                print("here")
                if (id.key == desiredIdCombo) {
                    self.pathId = desiredIdCombo
                    print("Path ID:", self.pathId)
//                    let ref1 = chatRef.childByAppendingPath(self.pathId)
//                    let newMessageForFirebase = ["senderId": currentUserUID]
//                    ref1.updateChildValues(newMessageForFirebase)
                    foundChat = true
                } else if (id.key == testIdCombo) {
                    self.pathId = testIdCombo
//                    let ref2 = chatRef.childByAppendingPath(self.pathId)
//                    let newMessageForFirebase = ["senderId": currentUserUID]
//                    ref2.updateChildValues(newMessageForFirebase)
                    foundChat = true
                }
            }
            if (!foundChat){
                self.pathId = desiredIdCombo
                print("Path ID:", self.pathId)
//                let ref1 = chatRef.childByAppendingPath(self.pathId)
//                let newMessageForFirebase = ["senderId": currentUserUID]
//                ref1.updateChildValues(newMessageForFirebase)
            }
            completionHandler()
        })
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        let currentUserUID = defaults.valueForKey("User ID") as? String ?? "i don't know"
        
        let chatRef = ref.childByAppendingPath("chats")
        let itemRef = chatRef.childByAppendingPath(self.pathId).childByAutoId()
        let newMessageForFirebase = ["senderId": currentUserUID, "messageContent": text]
        itemRef.updateChildValues(newMessageForFirebase)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
    }
    
    private func setupBubbles() {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = bubbleImageFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = bubbleImageFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    //------------------------------------------------------------------------------------------------------------------------------------------
    
    func signupErrorAlert(title: String, message: String) {
        
        // Called upon signup error to let the user know signup didn't work.
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let action = UIAlertAction(title: "Yes", style: .Default) { (alert: UIAlertAction!) -> Void in
            self.revokePrincessPoint()
            self.setRejectionStatus()
            self.performSegueWithIdentifier("unwindSegueMainFeedVC", sender: self)
        }
        let action2 = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        alert.addAction(action)
        alert.addAction(action2)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func revokePrincessPoint() {
        
        // Revokes princess point
        let userID = self.defaults.valueForKey("User ID") as! String
        let childRef = ref.childByAppendingPath("/princessPoints")
        let selectedChatUserRef = childRef.childByAppendingPath(selectedChatUserId)
        let userRef = childRef.childByAppendingPath(userID)
        
        let giveRef = userRef.childByAppendingPath("givenTo")
        let selectedUserRef = giveRef.childByAppendingPath(selectedChatUserId)
        selectedUserRef.removeValue()
        
        let receievedRef = selectedChatUserRef.childByAppendingPath("receivedFrom")
        let userIdRef = receievedRef.childByAppendingPath(userID)
        userIdRef.removeValue()
    }
    
    func setRejectionStatus() {
        
        let userID = self.defaults.valueForKey("User ID") as! String
        let childRef = ref.childByAppendingPath("/princessPoints")
        
        // rejectedBy
        let selectedUserRef = childRef.childByAppendingPath(selectedChatUserId)
        let rejectedByRef = selectedUserRef.childByAppendingPath("rejectedBy") // adds bucket in Firebase
        let rejectedByValue = ["rejectedBy": userID]
        
        // rejected
        let userRef = childRef.childByAppendingPath(userID)
        let rejectedRef = userRef.childByAppendingPath("rejected") // adds bucket in Firebase
        let rejectedValue = ["rejected": selectedChatUserId]
        
        rejectedRef.childByAppendingPath(selectedChatUserId).updateChildValues(rejectedValue) // adds point
        rejectedByRef.childByAppendingPath(userID).updateChildValues(rejectedByValue) // add
    }
}
