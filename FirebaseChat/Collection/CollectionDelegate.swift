//
//  CollectionDelegate.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 13/01/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation

protocol CollectionDelegate : class {
    func didDeleteItem(atIndex index: Int, items: [Any])
    func didUpdateItem(atIndex index: Int, items: [Any])
    func didAddItem(atIndex index: Int, items: [Any])
    func didUpdate(items: [Any])
    func didLoadNextPage(items: [Any])
}

extension CollectionDelegate {
    func didDeleteItem(atIndex index: Int, items: [Any]) {
        didUpdate(items: items)
    }
    func didUpdateItem(atIndex index: Int, items: [Any]) {
        didUpdate(items: items)
    }
    func didAddItem(atIndex index: Int, items: [Any]) {
        didUpdate(items: items)
    }
    func didLoadNextPage(items: [Any]) {
        didUpdate(items: items)
    }
}
