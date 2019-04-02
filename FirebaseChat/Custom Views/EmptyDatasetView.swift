//
//  EmptyDatasetView.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 27/02/2019.
//  Copyright © 2019 Curly Bracers. All rights reserved.
//

import UIKit

class EmptyDatasetView: UIView {
    
    static let classTag : Int = 2893748

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    var action: (()->Void)? {
        didSet {
            if action != nil {
                actionButton.isHidden = false
            } else {
                actionButton.isHidden = true
            }
        }
    }
    
    static func instantiate() -> EmptyDatasetView? {
        return Bundle.main.loadNibNamed("EmptyDatasetView", owner: nil, options: nil)?.first as? EmptyDatasetView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.text = nil
        descriptionLabel.text = nil
        actionButton.setTitle(nil, for: .normal)
        actionButton.isHidden = true
    }

    @IBAction func buttonTapped(_ sender: Any) {
        action?()
    }
    
}

extension UIView {
    
    func emptyDatasetView() -> EmptyDatasetView? {
        var view = viewWithTag(EmptyDatasetView.classTag)
        if view?.superview != self {
            view = nil
        }
        return view as? EmptyDatasetView
    }
    
    func showEmptyDataset(title: String, subtitle: String, buttonTitle: String? = nil, action: (()->Void)? = nil) {
        var view = emptyDatasetView()
        
        if view == nil {
            view = EmptyDatasetView.instantiate()
            view?.tag = EmptyDatasetView.classTag
            view?.backgroundColor = backgroundColor
            view?.embed(intoContainerView: self)
        }
        
        view?.isHidden = false
        view?.titleLabel.text = title
        view?.descriptionLabel.text = subtitle
        view?.action = action
        view?.actionButton.setTitle(buttonTitle, for: .normal)
        
        if let view = view {
            bringSubviewToFront(view)
        }
    }
    
    func hideEmptyDataset() {
        var view = emptyDatasetView()
        while view != nil {
            if let view = view {
                view.removeFromSuperview()
            }
            view = emptyDatasetView()
        }
    }
}
