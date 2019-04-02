//
//  FirebaseDatabaseRESTAPI.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 15/02/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class FirebaseDatabaseRESTAPI {
    static let shared = FirebaseDatabaseRESTAPI()
    private init() { }
    
    
    func get<T : FirebaseModel>(query: DatabaseQuery, shallow: Bool = false, completion: @escaping (_ items: [T], _ error: Error?)->Void) {
        get(query: query, shallow: shallow) { (response: [String : Any]?, error: Error?) in
            guard let response = response else {
                completion([T](), nil)
                return
            }
            var items = [T]()
            items = response.map({ (arg0) -> T in
                return T(id: arg0.key)
            })
            completion(items, error)
        }
    }
    
    func get(query: DatabaseQuery, shallow: Bool = false, completion: @escaping (_ response: [String : Any]?, _ error: Error?)->Void) {
        guard let authToken = Firebase.authToken else {
            completion(nil, NSError(domain: "Unauthorized", code: 503, userInfo: nil))
            return
        }
        
        var parameters : [String : Any] = [
            "auth" : authToken,
            "shallow" : shallow.JSONValue
        ]
        
        parameters.addValues(fromDictionary: query.RESTAPIparameters)
        
        
        let parameterString = parameters.map { (tuple) -> String in
            return "\(tuple.key)=\(tuple.value)"
            }.joined(separator: "&")
        guard let url = URL(string: query.ref.url + ".json?\(parameterString))") else {
            //        guard let url = URL(string: "https://\(databaseName).firebaseio.com/\(path).json?auth=\(authToken)") else {
            completion(nil, NSError(domain: "Incorrect URL", code: 400, userInfo: nil))
            return
        }
        URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            
            do {
                if let data = data, let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
                    completion(json, error)
                } else {
                    completion(nil, error)
                }
            } catch let error {
                completion(nil, error)
            }
            }.resume()
    }
}

protocol JSONRepresentible {
    var JSONValue : String { get }
}

extension Bool : JSONRepresentible {
    var JSONValue : String {
        return self ? "true" : "false"
    }
}
