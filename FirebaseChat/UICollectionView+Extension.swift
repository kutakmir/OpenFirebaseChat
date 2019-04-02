//
//  UICollectionView+Extension.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 17/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func scrollDirection() -> UICollectionView.ScrollDirection {
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            return layout.scrollDirection
        } else {
            return .vertical
        }
    }
    
}
