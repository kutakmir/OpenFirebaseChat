//
//  SectionedTableViewDataSource.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 27/02/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import UIKit

class SectionedTableViewDataSource : NSObject, UITableViewDataSource, UITableViewDelegate {
    
    override init() {
        super.init()
    }
    
    init(tableView: UITableView) {
        super.init()
        
        // Table View
        self.tableView = tableView
        tableView.dataSource = self
    }
    
    weak var tableView: UITableView?
    var sections = [Section]()
    private var visibleSections : [Section] {
        return sections.filter({ $0.isHidden == false })
    }
    var itemSelected: ((_ item: Any)->Void)? = nil
    
    func itemAtIndexPath(_ indexPath: IndexPath) -> Any {
        return visibleSections[indexPath.section].items[indexPath.row]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return visibleSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleSections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = visibleSections[indexPath.section]
        if section.items.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "nothing", for: indexPath)
        } else {
            let item = itemAtIndexPath(indexPath)
            let cellIdentifier = section.cellIdentifier ?? String(describing: type(of: item))
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            if let c = cell as? Configurable {
                c.configure(item: item)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sec = visibleSections[section]
        guard let headerIdentifier = sec.headerIdentifier, let title = sec.title else { return nil }
        let sectionHeader = tableView.dequeueReusableCell(withIdentifier: headerIdentifier, for: IndexPath(row: 0, section: section)) as! (UITableViewCell & Configurable)
        sectionHeader.configure(item: title)
        return sectionHeader
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
        let item = itemAtIndexPath(indexPath)
        itemSelected?(item)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return visibleSections[section].sectionHeaderHeight
    }
    

}
