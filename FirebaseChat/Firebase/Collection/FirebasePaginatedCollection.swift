//
//  FirebasePaginatedCollection.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebasePaginatedCollection<T : FirebaseModel> : FirebaseCollection<T>, PaginatedCollection {
    
    var pageSize : UInt = 4 /// DJ: Miro said this is the number of messages that are preloaded.
    private var nextPageQuery: DatabaseQuery?
    
    public private(set) var isLoadingNextPage : Bool = false
    public private(set) var hasLoadedAllOlderItems : Bool = false
    
    
    /**
     Initializes the FirebaseCollection with a Firebase Real-time Database Query.
     The reversedProjection flag determines how the data should be presented (ascending / descending)
     */
    init(query: DatabaseQuery, pageSize: UInt, reversedProjection: Bool = false, firstPageQuery: DatabaseQuery? = nil) {
        
        super.init()
        self.pageSize = pageSize
        self.reversedProjection = reversedProjection
        
        // Queries
        self.query = query.queryOrderedByKeyIfNeeded()
        nextPageQuery = self.query?.queryLimited(toFirst: pageSize)
        
        // To preserve the order of items and reduce the number of calls, we will first load all the content that matches our query and then we start observing for the changes (insertions, deletions, modifications)
        loadNextPage(query: firstPageQuery) { [weak self] in
            self?.startObserving()
        }
    }
    
    // ----------------------------------------------------
    // MARK: - Loading Older content - static
    // ----------------------------------------------------
    
    func loadNextPage(_ completion: (() -> Void)?) {
        loadNextPage(query: nil, completion)
    }
    
    func loadNextPage(query: DatabaseQuery? = nil, _ completion: (()->Void)? = nil) {
        
        let pageSize = self.pageSize
        
        var query : DatabaseQuery? = query ?? (nextPageQuery ?? self.query)
        var skipFirst = false
        var isLoadingFirstPage = false
        if let oldestMessage = rawItems.last {
            query = nextPageQuery?.queryStarting(atValue: oldestMessage.id)
            skipFirst = true
        } else {
            query = self.query?.queryLimited(toFirst: pageSize)
            isLoadingFirstPage = true
        }
        isLoadingNextPage = true
        
        query?.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            
            var items = [T]()
            var i = 0
            let children = snapshot.children.allObjects as! [DataSnapshot]
            for child in children {
                
                // Skip the first one (it's the same as the oldest message)
                if i == 0 && skipFirst {
                    i += 1
                    continue
                }
                
                if let item : T = self?.item(snapshot: child) {
                    items.append(item)
                }
                
                i += 1
            }
            
            self?.rawItems += items
            
            DispatchQueue.main.async {
                self?.isLoadingNextPage = false
            
                if children.count == pageSize {
                    // Everything ok, regular batch
                } else {
                    // We have reached the end of the list
                    self?.hasLoadedAllOlderItems = true
                }
                
                if isLoadingFirstPage {
                    self?.delegate?.didUpdate(items: self!.items)
                } else {
                    self?.delegate?.didLoadNextPage(items: self!.items)
                }
                completion?()
            }
        })
    }
}


