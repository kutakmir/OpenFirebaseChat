//
//  TableViewDataSource.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 24/07/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import UIKit

class TableViewDataSource : NSObject, UITableViewDataSource, UITableViewDelegate, CollectionDelegate {
    
    var tableViewDelegate: UITableViewDelegate?
    
    override init() {
        super.init()
    }
    
    init(tableView: UITableView) {
        super.init()
        
        // Table View
        self.tableView = tableView
        tableView.dataSource = self
        tableView.delegate = self
    }
    
//    weak var delegate : DataSourceDelegate?
    weak var tableView: UITableView?
    
    public private(set) var lastUsedNumberOfRowsInSection : Int = 0
    var rowAnimation : UITableView.RowAnimation = .none
    
    var items = [Any]()
    var itemSelected: ((_ item: Any)->Void)? = nil
    
    // ----------------------------------------------------
    // MARK: - UITableViewDataSource
    // ----------------------------------------------------
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if items.count == 0 && tableView.dequeueReusableCell(withIdentifier: "nothing") != nil {
            lastUsedNumberOfRowsInSection = 1
        } else {
            lastUsedNumberOfRowsInSection = items.count
        }
        
        return lastUsedNumberOfRowsInSection
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if items.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "nothing", for: indexPath)
        } else {
            let item = items[indexPath.row]
            let cellIdentifier = String(describing: type(of: item))
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            if let c = cell as? Configurable {
                c.configure(item: item)
            }
            return cell
        }
    }
    
    
    // ----------------------------------------------------
    // MARK: - UITableViewDelegate
    // ----------------------------------------------------
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        itemSelected?(item)
        tableViewDelegate?.tableView?(tableView, didSelectRowAt: indexPath)
    }
    
    
    // ----------------------------------------------------
    // MARK: - CollectionDelegate
    // ----------------------------------------------------
    
    func didUpdate(items: [Any]) {
        self.items = items
        tableView?.reloadData()
    }
    
    func didDeleteItem(atIndex index: Int, items: [Any]) {
        if rowAnimation == .none {
            didUpdate(items: items)
        } else {
            tableView?.beginUpdates()
            self.items = items
            tableView?.deleteRows(at: [IndexPath(row: index, section: 0)], with: rowAnimation)
            tableView?.endUpdates()
        }
    }
    
    func didUpdateItem(atIndex index: Int, items: [Any]) {
        if rowAnimation == .none {
            didUpdate(items: items)
        } else {
            tableView?.beginUpdates()
            self.items = items
            tableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: rowAnimation)
            tableView?.endUpdates()
        }
    }
    
    func didAddItem(atIndex index: Int, items: [Any]) {
        if rowAnimation == .none {
            didUpdate(items: items)
        } else {
            tableView?.beginUpdates()
            self.items = items
            tableView?.insertRows(at: [IndexPath(row: index, section: 0)], with: rowAnimation)
            tableView?.endUpdates()
        }
    }
    
}
