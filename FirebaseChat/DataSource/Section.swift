//
//  Section.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 27/02/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import Foundation
import UIKit

class Section : CollectionDelegate {
    
    var refreshDelegate: Refreshable?
    
    var sectionHeaderHeight: CGFloat
    var title : String?
    var isHidden : Bool {
        return items.count == 0
    }
    var headerIdentifier : String?
    var cellIdentifier : String?
    var items = [Any]()
    var icon: UIImage?
    var numberOfColumns: Int = 1
    var action: ((_ section: Section?) -> Void)?
    
    class func sections(fromArray array: [Any], sectionTitleBlock: @escaping (_ evaluatedObject: Any?) -> String) -> [Any]? {
        
        var itemsByKey = [AnyHashable: Any]()
        for object in array {
            let key = sectionTitleBlock(object)
            var sec = itemsByKey[key] as? [Any]
            if sec == nil {
                sec = [Any]()
                if let aSec = sec {
                    itemsByKey[key] = aSec
                }
            }
            
            sec?.append(object)
        }
        
        var sections = [Section]()
        let sortedKeys = ((itemsByKey as NSDictionary).allKeys as! [String]).sorted()
        for key in sortedKeys {
            let items = itemsByKey[key] as? [Any] ?? [Any]()
            let section = Section(title: key, items: items)
            section.title = key
            sections.append(section)
        }
        
        return sections
    }
    
    init(title: String?, sectionHeaderHeight: CGFloat = 44.0, iconName: String? = nil, headerIdentifier: String? = nil, cellIdentifier: String? = nil, items: [Any], action: ((_ section: Section?) -> Void)? = nil) {
        
        self.sectionHeaderHeight = sectionHeaderHeight
        self.title = title
        self.items = items
        self.cellIdentifier = cellIdentifier
        self.headerIdentifier = headerIdentifier
        self.action = action
        icon = UIImage(named: iconName ?? "")
        
    }
    
    // ----------------------------------------------------
    // MARK: - CollectionDelegate
    // ----------------------------------------------------
    
    func didUpdate(items: [Any]) {
        self.items = items
        refreshDelegate?.refresh(self)
    }
}
