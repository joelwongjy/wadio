//
//  CountdownViewController.swift
//  ORD
//
//  Created by Joel Wong on 7/4/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import UIKit

class CountdownViewController: UIViewController {

    @IBOutlet weak var countdownDays: UILabel!
    @IBOutlet weak var eventName: UILabel!
    
    var name: String?
    var days: String?
    var startDate: Date?
    var endDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        countdownDays.text = days
        eventName.text = "days to \(name!)"
        
        if startDate! < date && startDate != endDate {
            eventName.text = "days to end of \(name!)"
        }
    }
}
