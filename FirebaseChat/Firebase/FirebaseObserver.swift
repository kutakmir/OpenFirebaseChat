//
//  FirebaseObserver.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 19/02/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseModelObserver<T : FirebaseModel>: FirebaseObserver<T> {
    override var value: T? {
        return snapshot != nil ? T(snapshot: snapshot!) : nil
    }
}

class FirebaseModelArrayObserver<T : FirebaseModel>: FirebaseObserver<Array<T>> {
    override var value: Array<T>? {
        if let snapshots = snapshot?.childrenSnapshots {
            let array : [T] = firebaseModelArray(snapshots: snapshots)
            return array
        }
        return nil
    }
}

class FirebaseObserver<T> {
    
    var query : DatabaseQuery
    private var handle : DatabaseHandle?
    
    var snapshot: DataSnapshot?
    var value : T? {
        return snapshot?.value as? T
    }
    
    private init() { query = Firebase.database().reference() }
    init(reference: DatabaseQuery) {
        self.query = reference
    }
    
    func stopObserving() {
        if let handle = handle {
            query.removeObserver(withHandle: handle)
        }
    }
    
    // FIXME: unite this
    func startObservingValue(_ completion: ((_ value: T?)->Void)? = nil) {
        startObserving { [weak self] (snapshot) in
            // TODO: support more types, ideally use the same function as in the FirebaseModel's attribute's dictionary
            completion?( self?.value )
        }
    }
    
    func startObserving(_ completion: ((_ snapshot: DataSnapshot)->Void)? = nil) {
        stopObserving()
        handle = query.observe(.value, with: { [weak self] (snap) in
            self?.snapshot = snap
            completion?(snap)
        })
    }
    
    func submit(value: T) {
        if isFirebaseCompatibleValue(value: value) {
            query.ref.setValue(value)
        } else if let model = value as? FirebaseModel {
            query.ref.setValue(model.dictionary())
        }
        // TODO: support more types, ideally use the same function as in the FirebaseModel's attribute's dictionary
    }
    
    deinit {
        // Stop the attachment
        stopObserving()
    }
}


class FirebaseObserverFactory {
    
    static func boolValueObserver(reference: DatabaseQuery, completion: @escaping (_ isTrue: Bool)->Void) -> FirebaseObserver<Bool>? {
        let observer = FirebaseObserver<Bool>(reference: reference)
        observer.startObserving { (snap) in
            completion((snap.value as? Bool) ?? false)
        }
        return observer
    }
    
    static func boolObserver(reference: DatabaseQuery, completion: @escaping (_ isTrue: Bool)->Void) -> FirebaseObserver<Bool>? {
        let observer = FirebaseObserver<Bool>(reference: reference)
        observer.startObserving { (snap) in
            completion(snap.exists())
        }
        return observer
    }
    
    static func countObserver(reference: DatabaseQuery, completion: @escaping (_ count: Int)->Void) -> FirebaseObserver<Int>? {
        let observer = FirebaseObserver<Int>(reference: reference)
        observer.startObserving { (snap) in
            completion(snap.value as? Int ?? 0)
        }
        return observer
    }
}

