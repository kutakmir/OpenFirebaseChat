//
//  DataSourceDelegate.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 13/02/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import UIKit

protocol DataSourceDelegate : class {
    func dataSource(_ dataSource : Any, didSelectItem item: Any, atIndexPath: IndexPath)
}
