//
//  SelfHandlingItem.swift
//  Curly Bracers
//
//  Created by Miroslav Kuťák on 15/02/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertAction.Style {
    func rowActionStyle() -> UITableViewRowAction.Style {
        switch self {
        case .destructive:
            return .destructive
        default:
            return .default
        }
    }
}

class SelfHandlingItem : NSObject, Refreshable {
    
    weak var refreshableTarget: Refreshable?
    
    var title: String?
    var image: UIImage?
    var selectedImage: UIImage?
    var action: ()->Void = {}
    var style: UIAlertAction.Style = .default
    var isEnabled = true
    var isSelected = false
    
    
    var currentImage: UIImage? {
        return isSelected ? selectedImage : image
    }
    
    override init() {}
    
    init(title: String? = nil, imageName: String? = nil, selectedImageName: String? = nil, style: UIAlertAction.Style = .default, action: @escaping ()->Void) {
        self.title = title
        self.style = style
        
        if let imageName = imageName {
            image = UIImage(named: imageName)
        } else {
            image = nil
        }
        if let selectedImageName = selectedImageName {
            selectedImage = UIImage(named: selectedImageName)
        } else {
            selectedImage = nil
        }
        
        self.action = action
    }
    
    func refresh(_ sender: Any?) {
        refreshableTarget?.refresh(self)
    }
    
    
    static func presentActionSheet(items: [SelfHandlingItem], title: String? = nil) {
        
        let sheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        for option in items {
            sheet.addAction(UIAlertAction(title: option.title, style: option.style, handler: { (action) in
                option.action()
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        UIViewController.topMostController().present(sheet, animated: true, completion: nil)
    }
}
