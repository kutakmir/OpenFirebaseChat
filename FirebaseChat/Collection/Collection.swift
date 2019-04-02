//
//  Collection.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation

class Collection <T : Any> where T : Equatable {
    /**
     Reverses the order of items array dynamically
     */
    var reversedProjection : Bool = false
    
    /**
     We can also filter the items if needed
     */
    var filteringPredicate : NSPredicate?
    
    /**
     We can sort the filtered array of items
     */
    var sortingFunction : ((_ a: T, _ b: T) -> Bool)?
    
    /**
     The rawItems array contains all the elements in the original order
     */
    var rawItems = [T]()
    /**
     The items array projects the rawItems according to the rules set in either Collection class or it's subclasses.
     */
    var items : [T] {
        get {
            var filteredItems = rawItems
            
            // Returns the items based on the order defined by reversedProjection
            if reversedProjection {
                filteredItems.reverse()
            }
            
            if let filteringPredicate = filteringPredicate {
                filteredItems = (filteredItems as NSArray).filtered(using: filteringPredicate) as! [T]
            }
            
            if let sortingFunction = sortingFunction {
                filteredItems.sort(by: sortingFunction)
            }
            
            return filteredItems
        }
        set {
            rawItems = newValue
        }
    }
    
    /**
     An object that responds to the collection updates
     */
    weak var delegate: CollectionDelegate?
    
    
    // ----------------------------------------------------
    // MARK: - Initialization
    // ----------------------------------------------------
    
    init(items: [T]) {
        rawItems = items
    }
    init() {
    }
    
    func itemUpdated(_ item: T) {
        DispatchQueue.main.async {
            if let index = self.items.firstIndex(of: item) {
                self.delegate?.didUpdateItem(atIndex: index, items: self.items)
            }
        }
    }
    
    func itemsUpdated() {
        DispatchQueue.main.async {
            self.delegate?.didUpdate(items: self.items)
        }
    }
}
