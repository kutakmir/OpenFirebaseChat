//
//  FirestorePaginatedCollection.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 17/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

//class FirestorePaginatedCollection<T : FirestoreModel> : Collection<T> {
//    
//    private let pageSize : UInt = 15
//    
//    private var latestItemsHandle: DatabaseHandle?
//    private var latestItemsQuery: DatabaseQuery?
//    
//    private var changeItemHandle: DatabaseHandle?
//    private var deleteItemHandle: DatabaseHandle?
//    
//    private var nextPageQuery: DatabaseQuery?
//    private var query: DatabaseQuery?
//    var keepItemsAttached : Bool = false
//    
//    weak var delegate: CollectionDelegate?
//    
//    public private(set) var isLoadingNextPage : Bool = false
//    public private(set) var hasLoadedAllOlderItems : Bool = false
//    
//    init(query: DatabaseQuery) {
//        // QuerysetAttributes
//        self.query = query.queryOrderedByKey()
//        nextPageQuery = self.query?.queryLimited(toFirst: pageSize)
//        
//        super.init()
//        
//        loadNextPage { [weak self] in
//            self?.startObserving()
//        }
//    }
//    
//    deinit {
//        // Stop observing
//        stopObserving()
//    }
//    
//    // ----------------------------------------------------
//    // MARK: - Item Generation and Observation
//    // ----------------------------------------------------
//    
//    private func item(snapshot: DataSnapshot) -> T? {
//        if snapshot.exists(), let newObject = instantiateSwiftClassOfElementFromArray(any: self.items) as? T {
//            newObject.id = snapshot.key
//            newObject.reference = snapshot.ref
//            //            newObject.fetchedReference = snapshot.ref
//            
//            if let attributes = snapshot.value as? [String : AnyObject] {
//                newObject.setAttributes(attributes)
//            } else if let attribute = snapshot.value {
//                // Only a reference
//                newObject.setAttribute(attribute)
//                // We need to attach the item
//                if !keepItemsAttached {
//                    newObject.attachOnce { [weak self] in
//                        // Update UI for this particular item
//                        DispatchQueue.main.async {
//                            if let index = self?.items.index(of: newObject) {
//                                
//                                if newObject.exists {
//                                    self?.delegate?.didUpdateItem(atIndex: index, items: self!.items)
//                                } else {
//                                    self?.items.remove(at: index)
//                                    self?.delegate?.didDeleteItem(atIndex: index, items: self!.items)
//                                }
//                            }
//                        }
//                    }// End of attach
//                }
//            }
//            
//            if keepItemsAttached {
//                newObject.observeAndKeepAttached {
//                    // Update UI for this particular item
//                    DispatchQueue.main.async { [weak self] in
//                        if let index = self?.items.index(of: newObject) {
//                            
//                            if newObject.exists {
//                                self?.delegate?.didUpdateItem(atIndex: index, items: self!.items)
//                            } else {
//                                self?.items.remove(at: index)
//                                self?.delegate?.didDeleteItem(atIndex: index, items: self!.items)
//                            }
//                        }
//                    }
//                }// End of attach
//            }
//            
//            return newObject
//        } else {
//            return nil
//        }
//    }
//    
//    // ----------------------------------------------------
//    // MARK: - Observation - dynamic
//    // ----------------------------------------------------
//    
//    func startObserving() {
//        stopObserving()
//        
//        latestItemsQuery = query
//        if let firstItemId = items.first?.id {
//            latestItemsQuery = query?.queryEnding(atValue: firstItemId)
//        }
//        
//        // From that moment on, observe new incoming messages
//        latestItemsHandle = latestItemsQuery?.observe(.childAdded, with: { [weak self] (snapshot) in
//            // Validate the input
//            if let item : T = self?.item(snapshot: snapshot) {
//                
//                DispatchQueue.main.async {
//                    if let _self = self {
//                        if let first = _self.items.first, first == item {
//                            return
//                        }
//                        _self.items.insert(item, at: 0)
//                        _self.delegate?.didAddItem(atIndex: 0, items: self!.items)
//                    }
//                }
//            }
//        })
//        
//        deleteItemHandle = query?.observe(.childRemoved, with: { [weak self] (snapshot) in
//            guard let _self = self else { return }
//            
//            DispatchQueue.main.async {
//                var index = 0
//                for item in _self.items {
//                    if item.id == snapshot.key {
//                        
//                        self?.items.remove(at: index)
//                        self?.delegate?.didDeleteItem(atIndex: index, items: self!.items)
//                        break
//                    }
//                    index += 1
//                }
//            }
//        })
//        
//        changeItemHandle = query?.observe(.childChanged, with: { [weak self] (snapshot) in
//            guard let _self = self else { return }
//            
//            DispatchQueue.main.async {
//                var index = 0
//                for item in _self.items {
//                    if item.id == snapshot.key {
//                        
//                        self?.delegate?.didUpdateItem(atIndex: index, items: self!.items)
//                        break
//                    }
//                    index += 1
//                }
//            }
//        })
//    }
//    
//    func stopObserving() {
//        if let latestItemsHandle = latestItemsHandle {
//            latestItemsQuery?.removeObserver(withHandle: latestItemsHandle)
//        }
//        if let deleteItemHandle = deleteItemHandle {
//            query?.removeObserver(withHandle: deleteItemHandle)
//        }
//    }
//    
//    // ----------------------------------------------------
//    // MARK: - Loading Older content - static
//    // ----------------------------------------------------
//    
//    func loadNextPage(_ completion: (()->Void)? = nil) {
//        /*
//         - create the limited query based on the oldest message and a number of messages we will load
//         - after getting those snapshots append them to the end of the collection
//         - if there are no snapshots, hide the button (we have reached the oldest message)
//         */
//        
//        let pageSize = self.pageSize
//        
//        var query : DatabaseQuery? = nextPageQuery
//        var skipFirst = false
//        if let oldestMessage = items.last {
//            query = nextPageQuery?.queryStarting(atValue: oldestMessage.id)
//            skipFirst = true
//        } else {
//            query = self.query?.queryLimited(toFirst: pageSize)
//        }
//        isLoadingNextPage = true
//        
//        query?.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
//            
//            var items = [T]()
//            var i = 0
//            let children = snapshot.children.allObjects as! [DataSnapshot]
//            for child in children {
//                
//                // Skip the first one (it's the same as the oldest message)
//                if i == 0 && skipFirst {
//                    i += 1
//                    continue
//                }
//                
//                // i know all the participants in a conversation.  I just need participant by ID
//                // i want to be able to use onfigurable
//                if let item : T = self?.item(snapshot: child) {
//                    items.append(item)
//                }
//                
//                i += 1
//            }
//            
//            self?.items += items
//            
//            DispatchQueue.main.async {
//                self?.delegate?.didUpdate(items: self!.items)
//                self?.isLoadingNextPage = false
//                
//                if children.count == pageSize {
//                    // everything ok, regular batch
//                } else {
//                    // We have reached the end of the list
//                    self?.hasLoadedAllOlderItems = true
//                }
//                
//                completion?()
//            }
//        })
//    }
//}
