//
//  PaginatedCollectionViewDataSource.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 13/01/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import UIKit

class PaginatedCollectionViewDataSource<T: FirebaseModel>: CollectionViewDataSource<T> {
    
    init(collectionView: UICollectionView, pageSize: UInt, newPageDetectionThreshold: CGFloat, cellClass: AnyClass? = nil, reversedProjection: Bool = false) {
        super.init(collectionView: collectionView, cellClass: cellClass)
    }
    
    /**
     Convenience computed property that helps with casting the collection as PaginatedCollection
     */
    var paginatedCollection : (Collection<T> & PaginatedCollection) {
        return collection as! (Collection<T> & PaginatedCollection)
    }
    
    // ----------------------------------------------------
    // MARK: - UI
    // ----------------------------------------------------
    var newPageDetectionThreshold : CGFloat = 100.0 /// DJ: 'newPageDetectionThreshold' is set in calling the function. 'newPageDetectionThreshold' is the CGFloat away that then causes another/more pages to load.
    var isCloseToTheEndOfScrolling : Bool {
        guard let collectionView = collectionView else { return false }
        
        if collectionView.scrollDirection() == .vertical {
            if collection.reversedProjection {
                return collectionView.contentOffset.y < newPageDetectionThreshold
            } else {
                return collectionView.contentSize.height - collectionView.contentOffset.y < newPageDetectionThreshold
            }
        } else {
            if collection.reversedProjection {
                return collectionView.contentOffset.x < newPageDetectionThreshold
            } else {
                return collectionView.contentSize.width  - collectionView.contentOffset.x < newPageDetectionThreshold
            }
        }
    }
    
    /**
     Performs the logic associated with scroll view scrolling.
     In particular we're checking if the scroll view is close to the end of scrolling (that could be either on the top or on the bottom of the UICollectionView, depending on if we fill the collection from the top or from the bottom).
     We're also checking if the the paginated collection isn't loading the next page already and lastly - we could also be in a situation where we know for sure that we've loaded all the content.
     */
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        if isCloseToTheEndOfScrolling && paginatedCollection.isLoadingNextPage == false && paginatedCollection.hasLoadedAllOlderItems == false {
            paginatedCollection.loadNextPage(nil)
        }
    }
    
    
    // ----------------------------------------------------
    // MARK: - CollectionDelegate
    // ----------------------------------------------------
    
    @objc func didLoadNextPage(items: [Any]) { /// DJ: Miro said that this is done to try to correct for case of inserting stuff at the top so there isn't jumping.
        guard let collectionView = collectionView else { return }
        
        if collectionView.scrollDirection() == .vertical {
            let contentHeight = collectionView.contentSize.height
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            let updatedContentHeight = collectionView.contentSize.height
            collectionView.contentOffset = CGPoint(x: 0, y: updatedContentHeight - contentHeight + collectionView.contentOffset.y)
        } else {
            let contentOffsetX = collectionView.contentOffset.x
            let contentWidth = collectionView.contentSize.width
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            let updatedContentOffsetX = collectionView.contentOffset.x
            let updatedContentWidth = collectionView.contentSize.width
            collectionView.contentOffset = CGPoint(x: updatedContentWidth - contentWidth + updatedContentOffsetX - contentOffsetX, y: 0)
        }
    }
}
