//
//  FirebaseCollection.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 18/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseCollection<T : FirebaseModel> : Collection<T> {
    
    private var latestItemsHandle: DatabaseHandle?
    private var latestItemsQuery: DatabaseQuery?
    
    private var changeItemHandle: DatabaseHandle?
    private var deleteItemHandle: DatabaseHandle?
    var query: DatabaseQuery?
    var keepItemsAttached : Bool = false
    
    /**
     Initializes the FirebaseCollection with a Firebase Real-time Database Query.
     The reversedProjection flag determines how the data should be presented (ascending / descending)
     */
    init(query: DatabaseQuery, reversedProjection: Bool = false) {
        self.query = query
        
        super.init()
        self.reversedProjection = reversedProjection
        
        // To preserve the order of items and reduce the number of calls, we will first load all the content that matches our query and then we start observing for the changes (insertions, deletions, modifications)
        loadCurrentContent { [weak self] in
            self?.startObserving()
        }
    }
    
    override init() {
        super.init()
    }
    
    deinit {
        // Stop observing
        stopObserving()
    }
    
    // ----------------------------------------------------
    // MARK: - Item Generation and Observation
    // ----------------------------------------------------
    
    func item(snapshot: DataSnapshot) -> T? {
        if snapshot.exists(), let newObject = instantiateSwiftClassOfElementFromArray(any: self.rawItems) as? T {
            newObject.id = snapshot.key
            newObject.reference = snapshot.ref
            
            if let attributes = snapshot.value as? [String : AnyObject] {
                newObject.setAttributes(attributes)
            } else if let attribute = snapshot.value {
                // Only a reference
                newObject.setAttribute(attribute)
                // We need to attach the item
                if !keepItemsAttached {
                    newObject.attachOnce { [weak self] in
                        // Update UI for this particular item
                        DispatchQueue.main.async {
                            if let index = self?.rawItems.index(of: newObject) {
                                
                                if newObject.exists {
                                    self?.delegate?.didUpdateItem(atIndex: index, items: self!.rawItems)
                                } else {
                                    self?.rawItems.remove(at: index)
                                    self?.delegate?.didDeleteItem(atIndex: index, items: self!.rawItems)
                                }
                            }
                        }
                    }// End of attach
                }
            }
            
            if keepItemsAttached {
                newObject.observeAndKeepAttached {
                    // Update UI for this particular item
                    DispatchQueue.main.async { [weak self] in
                        if let index = self?.rawItems.index(of: newObject) {
                            
                            if newObject.exists {
                                self?.delegate?.didUpdateItem(atIndex: index, items: self!.rawItems)
                            } else {
                                self?.rawItems.remove(at: index)
                                self?.delegate?.didDeleteItem(atIndex: index, items: self!.rawItems)
                            }
                        }
                    }
                }// End of attach
            }
            
            return newObject
        } else {
            return nil
        }
    }
    
    // ----------------------------------------------------
    // MARK: - Observation - dynamic
    // ----------------------------------------------------
    
    func startObserving() {
        stopObserving()
        
        latestItemsQuery = query
        
        // If there already is an item to base the latest query on - let's use it as a reference and observe new items only from that one on
        // This prevents fetching twice the same data we already have because .childAdded event gets called also for the data that already exist in the database, not just the newly added
        if let firstItemId = rawItems.first?.id {
            latestItemsQuery = query?.queryOrderedByKeyIfNeeded().queryEnding(atValue: firstItemId)
        }
        
        // From that moment on, observe new incoming messages
        latestItemsHandle = latestItemsQuery?.observe(.childAdded, with: { [weak self] (snapshot) in
            // Do not insert the existing records
            if let _ = self?.rawItems.index(of: snapshot) {
                return
            }
            
            // Validate the input - it must be parseable to the `T` type
            if let item : T = self?.item(snapshot: snapshot) {
                
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    
                    self.rawItems.insert(item, at: 0)
                    // We need to use the index of the projection rather than the rawItems
                    if let index = self.items.index(of: snapshot) {
                        self.delegate?.didAddItem(atIndex: index, items: self.items)
                    }
                }
            }
        })
        
        deleteItemHandle = query?.observe(.childRemoved, with: { [weak self] (snapshot) in
            guard let `self` = self else { return }
            
            DispatchQueue.main.async {
                
                if let rawIndex = self.rawItems.index(of: snapshot) {
                    if let index = self.items.index(of: snapshot) {
                        self.rawItems.remove(at: rawIndex)
                        self.delegate?.didDeleteItem(atIndex: index, items: self.items)
                    }
                }
            }
        })
        
        changeItemHandle = query?.observe(.childChanged, with: { [weak self] (snapshot) in
            guard let `self` = self else { return }
            
            DispatchQueue.main.async {
                if let index = self.rawItems.index(of: snapshot) {
                        
                    let model = T(snapshot: snapshot)!
                    self.rawItems.remove(at: index)
                    self.rawItems.insert(model, at: index)
                    
                    if let index = self.items.index(of: snapshot) {
                        self.delegate?.didUpdateItem(atIndex: index, items: self.items)
                    }
                }
            }
        })
    }
    
    func stopObserving() {
        if let latestItemsHandle = latestItemsHandle {
            latestItemsQuery?.removeObserver(withHandle: latestItemsHandle)
        }
        if let deleteItemHandle = deleteItemHandle {
            query?.removeObserver(withHandle: deleteItemHandle)
        }
        if let changeItemHandle = changeItemHandle {
            query?.removeObserver(withHandle: changeItemHandle)
        }
    }
    
    // ----------------------------------------------------
    // MARK: - Loading Current content - static
    // ----------------------------------------------------
    
    func loadCurrentContent(_ completion: (()->Void)? = nil) {
        
        query?.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            
            var items = [T]()
            let children = snapshot.children.allObjects as! [DataSnapshot]
            for child in children {
                
                if let item : T = self?.item(snapshot: child) {
                    items.append(item)
                }
            }
            
            self?.rawItems += items
            
            DispatchQueue.main.async {
                self?.delegate?.didUpdate(items: self!.items)
                completion?()
            }
        })
    }
}
