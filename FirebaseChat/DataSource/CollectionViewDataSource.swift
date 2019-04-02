//
//  CollectionViewDataSource.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 24/07/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import UIKit

class CollectionViewDataSource<T> : NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, CollectionDelegate where T : Equatable {
    
    /**
     The collection of items of type T.
     It's an array with some additional functionality.
     Can be easily subclassed and further extended.
     */
    var collection : Collection<T> {
        didSet {
            setupCollectionDelegate()
        }
    }
    
    func setupCollectionDelegate() {
        collection.delegate = self
    }
    
    weak var scrollViewDelegate : UIScrollViewDelegate?
    
    weak var collectionView : UICollectionView?
    var itemAnimation = true
    var shouldScrollToNewItem = true
    
    init(collectionView: UICollectionView, cellClass: AnyClass? = nil) {
        
        collection = Collection<T>()
        
        super.init()
        
        // Did set is not being called during init()
        setupCollectionDelegate()
        
        // Collection View
        self.collectionView = collectionView
        collectionView.dataSource = self
        collectionView.delegate = self
        
        
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        if let cellClass = cellClass {
            collectionView.register(cellClass, forCellWithReuseIdentifier: "\(T.self)")
        }
    }
    
    // ----------------------------------------------------
    // MARK: - UICollectionViewDataSource
    // ----------------------------------------------------
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collection.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = collection.items[indexPath.row]
        let cellIdentifier = String(describing: type(of: item))
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)

        if let c = cell as? Configurable {
            c.configure(item: item)
        }
        return cell
    }
    
    // ----------------------------------------------------
    // MARK: - CollectionDelegate
    // ----------------------------------------------------
    
    func didUpdate(items: [Any]) {
        collectionView?.reloadData()
        scrollToNewItem(animated: false)
    }
    
    func didDeleteItem(atIndex index: Int, items: [Any]) {
        if itemAnimation == false {
            // In case there is no animation, we can simply reload the entire collection view using the didUpdate(items:_) method
            didUpdate(items: items)
        } else {
            collectionView?.performBatchUpdates({ [weak self] in
                self?.collectionView?.deleteItems(at: [IndexPath(row: index, section: 0)])
                }, completion: nil)
        }
    }
    
    func didUpdateItem(atIndex index: Int, items: [Any]) {
        
        if let configurableCell = collectionView?.cellForItem(at: IndexPath(row: index, section: 0)) as? (UICollectionViewCell & Configurable) {
            configurableCell.configure(item: items[index])
        }
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func didAddItem(atIndex index: Int, items: [Any]) {
        if itemAnimation == false {
            didUpdate(items: items)
        } else {
            collectionView?.performBatchUpdates({ [weak self] in
                guard let `self` = self else { return }
                let indexPath = IndexPath(row: index, section: 0)
                self.collectionView?.insertItems(at: [indexPath])
                self.collectionView?.collectionViewLayout.invalidateLayout()
                }, completion: { finished in
                    
                    // When the updates are complete (the new item inserted) we should scroll to see the new item.
                    if finished && self.shouldScrollToNewItem {
                        self.scrollToNewItem(animated: true)
                    }
            })
        }
    }
    
    /**
     Convenience method to scrolling to the newest item
     */
    func scrollToNewItem(animated: Bool) {
        // Calling layoutIfNeeded() recalculates the content height that we need for the newItemContentOffset calculation
        collectionView?.layoutIfNeeded()
        collectionView?.setContentOffset(newItemContentOffset, animated: animated)
    }
    
    /**
     The content offset required to see the entire cell of the newest item
     */
    private var newItemContentOffset : CGPoint {
        if collection.reversedProjection {
            collectionView?.layoutIfNeeded()
            return CGPoint(x: 0, y: self.collectionView!.contentSize.height - self.collectionView!.frame.size.height)
        } else {
            return CGPoint.zero
        }
    }
    
    func indexPath(item: T) -> IndexPath? {
        if let i : Int = collection.items.index(of: item) {
            return IndexPath(item: i, section: 0)
        } else {
            return nil
        }
    }
    
    
    // ----------------------------------------------------
    // MARK: - UICollectionViewDelegateFlowLayout
    // ----------------------------------------------------
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) { /// DJ: I had to add this to 'CollectionViewDataSource' or else the functions for 'willDisplay cell' would not be called. My guess is because this base class sets up the delegate properly, but otherwise the higher-level versios do not.
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 80)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        
    }
    
    // ----------------------------------------------------
    // MARK: - UICollectionViewDelegate
    // ----------------------------------------------------
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    // ----------------------------------------------------
    // MARK: - UIScrollViewDelegate
    // ----------------------------------------------------
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidZoom?(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if let view = scrollViewDelegate?.viewForZooming?(in: scrollView) {
            return view
        }
        return nil
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
}
