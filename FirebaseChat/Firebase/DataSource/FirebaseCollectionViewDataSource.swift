//
//  FirebaseCollectionViewDataSource.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 18/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseCollectionViewDataSource<T: FirebaseModel>: CollectionViewDataSource<T> {
    
    
    /**
     Initializes the FirebaseCollectionViewDataSource with a Firebase Real-time Database Query.
     The reversedProjection flag determines how the data should be presented (ascending / descending)
     */
    init(query: DatabaseQuery, collectionView: UICollectionView, cellClass: AnyClass? = nil, reversedProjection: Bool = false) {
        super.init(collectionView: collectionView, cellClass: cellClass)
        
        collection = FirebaseCollection<T>(query: query, reversedProjection: reversedProjection)
    }
}

