//
//  RandomNameService.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 27/02/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation

class RandomNameService {
    static let shared = RandomNameService()
    private init() {}
    private let url = URL(string: "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-no-swears.txt")!
    
    func getRandomName(_ completion: @escaping (_ name: String) -> Void) {
        
        let task = URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data, let string = String(data: data, encoding: .utf8) {
                let words = string.components(separatedBy: "\n")
                completion(words.randomElement() ?? "Nobody")
            }
        }
        task.resume()
    }
}

extension Array {
    func randomElement() -> Element? {
        if isEmpty { return nil }
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}
