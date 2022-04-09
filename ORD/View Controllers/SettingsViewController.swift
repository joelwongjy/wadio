//
//  SettingsVC.swift
//  ORD
//
//  Created by Joel Wong on 9/1/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import Foundation
import UIKit
import StoreKit
import Eureka

protocol DestinationViewControllerDelegate: class {
    func updateData()
}

class settingsViewController: FormViewController {
    
    weak var delegate: DestinationViewControllerDelegate?
    let defaults = UserDefaults.standard
    
    @IBAction func doneButton(_ sender: UIButton) {
        navigationController?.dismiss(animated: true)
    }
    
    func buttonTapped(cell: ButtonCellOf<String>, row: ButtonRow) {
        if #available( iOS 10.3,*){
        SKStoreReviewController.requestReview()
        }
    }
    
    func getVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        return "Version \(version)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ Section("General")
            <<< DateInlineRow(){
                $0.title = "ORD Date"
                
                if defaults.value(forKey: "ordDate") == nil{
                    $0.value = date
                }
                else{
                    $0.value = (defaults.value(forKey: "ordDate") as! Date)
                }
                $0.minimumDate = date
                $0.maximumDate = calendar.date(byAdding: .year, value: 10, to: date)
            }.onChange{ (row) in
                self.defaults.set(row.value, forKey: "ordDate")
                self.delegate!.updateData()
                }
            
            <<< DateInlineRow(){
                $0.title = "POP Date"
                if defaults.value(forKey: "popDate") == nil{
                    $0.value = date
                }
                else{
                    $0.value = (defaults.value(forKey: "popDate") as! Date)
                }
                $0.minimumDate = calendar.date(byAdding: .year, value: -2, to: date)
                $0.maximumDate = calendar.date(byAdding: .year, value: 10, to: date)
            }.onChange{ (row) in
                self.defaults.set(row.value, forKey: "popDate")
                DataManager.shared.homeVC.displayInfo()
            }
            
            <<< ActionSheetRow<String>() {
                $0.title = "Service Term"
                $0.selectorTitle = "Service Term"
                $0.options = ["22 Months","24 Months"]
                if UserDefaults.standard.integer(forKey: "months") == 22{
                    $0.value = "22 Months"
                }
                else{
                    $0.value = "24 Months"
                }
            }.onChange{ (row) in
                if row.value == "24 Months"{
                    self.defaults.set(24, forKey: "months")
                }
                else if row.value == "22 Months"{
                    self.defaults.set(22, forKey: "months")
                }
                self.delegate!.updateData()
                }
            +++ Section(header: "Support", footer: getVersion())
                <<< ButtonRow() {
                    $0.title = "About"
                    $0.presentationMode = .segueName(segueName: "showAbout", onDismiss: nil)
                }
                <<< ButtonRow() {
                    $0.title = "Privacy Policy"
                    $0.presentationMode = .segueName(segueName: "showPolicy", onDismiss: nil)
                }
                <<< ButtonRow() {
                    $0.title = "Attributions"
                    $0.presentationMode = .segueName(segueName: "showAcknowledgements", onDismiss: nil)
                }
                <<< ButtonRow() {
                    $0.title = "Rate the App"
                    $0.onCellSelection(self.buttonTapped)
                }
    }
}
