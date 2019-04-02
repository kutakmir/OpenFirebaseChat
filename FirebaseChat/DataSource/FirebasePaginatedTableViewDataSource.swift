//
//  FirebasePaginatedTableViewDataSource.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 13/01/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import UIKit
import FirebaseDatabase
class FirebasePaginatedTableViewDataSource<T: FirebaseModel>: TableViewDataSource {
    
    let collection : FirebasePaginatedCollection<T>
    
    init(query: DatabaseQuery, tableView: UITableView) {
        collection = FirebasePaginatedCollection<T>(query: query, pageSize: 15)
        super.init(tableView: tableView)
        
        collection.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }
    
    // ----------------------------------------------------
    // MARK: - UI
    // ----------------------------------------------------
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.height - scrollView.contentOffset.y < 100.0 && collection.isLoadingNextPage == false && collection.hasLoadedAllOlderItems == false {
            collection.loadNextPage()
        }
    }
}
