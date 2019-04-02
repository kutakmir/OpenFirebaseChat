//
//  DatabaseQuery+Extension.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 12/12/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

extension DatabaseQuery {
    
    var startingAt : String? {
        return getValueOfParameter("sp = ")
    }
    
    var endingAt : String? {
        return getValueOfParameter("ep = ")
    }
    
    var limitToFirst : String? {
        if limitSide == "r" {
            return limit
        } else {
            return nil
        }
    }
    
    var limitToLast : String? {
        if limitSide == "l" {
            return limit
        } else {
            return nil
        }
    }
    
    var limitSide : String? {
        return getValueOfParameter("vf = ")
    }
    
    var limit : String? {
        return getValueOfParameter("l = ")
    }
    
    var orderedBy : String? {
        return getValueOfParameter("i = ")?.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: ".", with: "$")
    }
    
    var isOrderedByKey : Bool {
        if let orderedBy = orderedBy {
            return orderedBy == "$key"
        } else {
            return false
        }
    }
    
    /**
     Prevents duplicate ordering by key.
     Use this method instead of queryOrderedByKey - it's crash proof.
     */
    func queryOrderedByKeyIfNeeded() -> DatabaseQuery {
        if isOrderedByKey {
            return self
        } else {
            return self.queryOrderedByKey()
        }
    }
    
    private func getValueOfParameter(_ parameter: String) -> String? {
        if description.contains(parameter) {
            return description.components(separatedBy: parameter).last?.components(separatedBy: ";").first
        } else {
            return nil
        }
    }
    
    var RESTAPIparameters : [String : Any] {
        
        var parameters : [String : Any] = [:]
        
        // Ordering
        parameters["orderedBy"] = orderedBy ?? "$key"
        
        // Limit Queries
        parameters["limitToFirst"] = limitToFirst
        parameters["limitToLast"] = limitToLast
        
        // Range Queries
        parameters["endingAt"] = endingAt
        parameters["startingAt"] = startingAt
        
        return parameters
    }
    
}

extension DatabaseQuery {
    
    func getShallowJSON(completion: @escaping (_ response: [String : Any]?, _ error: Error?)->Void) {
        FirebaseDatabaseRESTAPI.shared.get(query: self, shallow: true, completion: completion)
    }
    
    func getShallow<T : FirebaseModel>(completion: @escaping (_ items: [T], _ error: Error?)->Void) {
        FirebaseDatabaseRESTAPI.shared.get(query: self, shallow: true, completion: completion)
    }
    
}
