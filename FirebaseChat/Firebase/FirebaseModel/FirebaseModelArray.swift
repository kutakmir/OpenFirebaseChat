
//
//  FirebaseModelArray.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

fileprivate var firebaseModelHandles = [DatabaseReference : DatabaseHandle]()

extension Array where Element:FirebaseModel {
    
    // TODO: create a nice, incrementally synced array
    func index(of element: DataSnapshot) -> Int? {
        var index = 0
        for item in self {
            if item.id == element.key {
                return index
            }
            index += 1
        }
        
        return nil
    }
    
}


func firebaseModelArray<T : FirebaseModel>(snapshots: [DataSnapshot]) -> [T] {
    return snapshots.compactMap({ T(snapshot: $0) })
}

extension DataSnapshot {
    
    var childrenSnapshots : [DataSnapshot] {
        if hasChildren() {
            return children.allObjects as! [DataSnapshot]
        } else {
            return [DataSnapshot]()
        }
    }
    
    func firebaseModelArrayFromChildren<T : FirebaseModel>() -> [T] {
        return childrenSnapshots.compactMap({ T(snapshot: $0) })
    }
    
}

extension DatabaseQuery {
    
    func get<T : FirebaseModel>(_ completion: @escaping (_ items : [T])->Void) {
        observe(.value) { (snapshot: DataSnapshot) in
            completion(snapshot.firebaseModelArrayFromChildren())
        }
    }
    
}
