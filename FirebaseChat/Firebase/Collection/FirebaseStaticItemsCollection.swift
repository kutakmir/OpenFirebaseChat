//
//  FirebaseStaticItemsCollection.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 17/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseStaticLiveItemsCollection <T: FirebaseModel> : Collection<T> {
    
    private var observations = [FirebaseObservation]()
    func removeAllObservers() {
        for observation in observations {
            observation.remove()
        }
        observations.removeAll()
    }
    
    func configure(items: [T], keepItemsAttached : Bool = false) {
        self.items = items
        
        delegate?.didUpdate(items: items)
        
        removeAllObservers()
        
        if keepItemsAttached {
            for item in items {
                let observation = item.observeAndKeepAttached { [weak self] in
                    if let index = self?.items.index(of: item) {
                        if item.exists {
                            self?.delegate?.didUpdateItem(atIndex: index, items: self!.items)
                        } else {
                            self?.items.remove(at: index)
                            self?.delegate?.didDeleteItem(atIndex: index, items: self!.items)
                        }
                    }
                }// End of observe
                
                if let observation = observation {
                    observations.append(observation)
                }
            }
        }
    }
}


class FirebaseStaticItemsCollection <T: FirebaseModel> : Collection<T> {
    
    private var observations = [FirebaseObservation]()
    func removeAllObservers() {
        for observation in observations {
            observation.remove()
        }
        observations.removeAll()
    }
    
    func configure(items: [T], keepItemsUpdated : Bool = false) {
        self.items = items
        
        delegate?.didUpdate(items: items)
        
        removeAllObservers()
        
        if keepItemsUpdated {
            for item in items {
                let observation = item.observeAndKeepAttached { [weak self] in
                    if let index = self?.items.index(of: item) {
                        self?.delegate?.didUpdateItem(atIndex: index, items: self!.items)
                    }
                }// End of observe
                
                if let observation = observation {
                    observations.append(observation)
                }
            }
        }
    }
}
