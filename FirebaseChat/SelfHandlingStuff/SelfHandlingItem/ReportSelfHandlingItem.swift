//
//  ReportSelfHandlingItem.swift
//  Curly Bracers
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit

class ReportSelfHandlingItem: SelfHandlingItem {
    
    init(reportedUser: FirebaseUser? = nil, reportedChannel: Channel? = nil) {
        super.init()
        title = "Report Abuse"
        
        action = presentPopup
        
        self.reportedUser = reportedUser
        self.reportedChannel = reportedChannel
    }
    
    var reportedUser : FirebaseUser?
    var reportedChannel : Channel?

    weak var createNewChannelTextField : UITextField?
    func presentPopup() {
        
        let alert = UIAlertController(title: "Report Abuse", message: "", preferredStyle: .alert)
        alert.addTextField { [weak self] (textField : UITextField) in
            textField.placeholder = "Type the reason why this content is inappropriate"
            self?.createNewChannelTextField = textField
        }
        let createAction = UIAlertAction(title: "Report", style: .destructive, handler: { [weak self] (action) in
            guard let name = self?.createNewChannelTextField?.text else { return }
            
            let report = Report()
            report.caption = name
            report.reportedUserNested = self?.reportedUser
            report.reportedChannelNested = self?.reportedChannel
            report.creatorNested = FirebaseUser.current
            
            report.save()
            
            let _ = UIAlertController.presentOKAlertWithTitle("Success", message: "Report sent")
        })
        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        UIViewController.topMostController().present(alert, animated: true, completion: nil)
    }
}
