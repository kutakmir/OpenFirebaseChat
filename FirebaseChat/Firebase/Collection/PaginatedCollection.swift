//
//  PaginatedCollection.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 13/01/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation

/**
 A protocol that extends Collection to PaginatedCollection so that we can have a unified way of handling pagination no matter the data source.
 */
protocol PaginatedCollection {
    
    var isLoadingNextPage : Bool {get}
    var hasLoadedAllOlderItems : Bool {get}
    var pageSize : UInt {get set}
    func loadNextPage(_ completion: (()->Void)?)
    
}
