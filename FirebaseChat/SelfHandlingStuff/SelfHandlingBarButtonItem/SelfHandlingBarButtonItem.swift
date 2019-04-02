//
//  SelfHandlingBarButtonItem.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class SelfHandlingBarButtonItem: UIBarButtonItem, Refreshable {
    
    var item: SelfHandlingItem? {
        didSet {
            // Refreshing
            item?.refreshableTarget = self
            refresh(nil)
        }
    }
    
    override init() {
        super.init()
        
        setup()
    }
    
    init(item: SelfHandlingItem) {
        self.item = item
        super.init()
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    func setup() {
        
        target = self
        action = #selector(didTap)
    }
    
    @objc func didTap() {
        item?.action()
    }
    
    // ----------------------------------------------------
    // MARK: - Refreshable
    // ----------------------------------------------------
    
    func refresh(_ sender: Any?) {
        self.title = item?.title
        if let item = item {
            self.image = item.currentImage
        } else {
            self.image = nil
        }
        
    }
}
