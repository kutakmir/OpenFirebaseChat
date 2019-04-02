//
//  SelfHandlingButton.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class SelfHandlingButton: UIButton, Refreshable {
    
    weak var refreshableTarget: Refreshable?
    
    var item: SelfHandlingItem? {
        didSet {
            // Refreshing
            item?.refreshableTarget = self
            refresh(self)
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        
        setup()
    }
    
    init(item: SelfHandlingItem) {
        self.item = item
        super.init(frame: CGRect.zero)
        
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
        
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }
    
    @objc func didTap() {
        item?.action()
    }
    
    // ----------------------------------------------------
    // MARK: - Refreshable
    // ----------------------------------------------------
    
    func refresh(_ sender: Any?) {
        setTitle(item?.title, for: .normal)
        setImage(item?.selectedImage, for: .selected)
        setImage(item?.image, for: .normal)
        
        refreshableTarget?.refresh(self)
    }
}

