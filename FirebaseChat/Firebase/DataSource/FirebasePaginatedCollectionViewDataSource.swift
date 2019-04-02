//
//  FirebasePaginatedCollectionViewDataSource.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 17/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import FirebaseDatabase

class FirebasePaginatedCollectionViewDataSource<T: FirebaseModel>: PaginatedCollectionViewDataSource<T> { /// DJ: Miro said this could become even more generic.
    
    
    /**
     Initializes the FirebaseCollectionViewDataSource with a Firebase Real-time Database Query.
     The reversedProjection flag determines how the data should be presented (ascending / descending)
     */
    init(query: DatabaseQuery, collectionView: UICollectionView, pageSize: UInt, newPageDetectionThreshold: CGFloat, cellClass: AnyClass? = nil, reversedProjection: Bool = false, firstPageQuery: DatabaseQuery? = nil) {
        super.init(collectionView: collectionView, pageSize: pageSize, newPageDetectionThreshold: newPageDetectionThreshold, cellClass: cellClass)
        collection = FirebasePaginatedCollection<T>(query: query, pageSize: pageSize, reversedProjection: reversedProjection, firstPageQuery: firstPageQuery)
    }
}
