//
//  SettingsBarButtonItem.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class MultiSelfHandlingBarButtonItem: SelfHandlingBarButtonItem {
    
    var options = [SelfHandlingItem]()
    var actionSheetTitle: String?
    
    init(options: [SelfHandlingItem]) {
        super.init()
        self.options = options
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setup() {
        super.setup()
        
        title = nil
        image = UIImage(named: "icons8-services")
    }
    
    @objc override func didTap() {
        // Present all options
        SelfHandlingItem.presentActionSheet(items: options, title: actionSheetTitle ?? title)
    }
    
}


class SettingsBarButtonItem: MultiSelfHandlingBarButtonItem {

    override func setup() {
        super.setup()
        
        title = nil
        image = UIImage(named: "icons8-services")
    }
}
