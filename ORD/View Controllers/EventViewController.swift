//
//  EventViewController.swift
//  ORD
//
//  Created by Joel Wong on 20/1/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import Eureka

class eventViewController: FormViewController{
    let defaults = UserDefaults.standard
    let today = date.addingTimeInterval(8*3600)
    
    @IBOutlet weak var addButton: UIButton!
    
    @IBAction func cancelEvent(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }
    
    @IBAction func addEvent(_ sender: UIButton) {
        let event = form.values()
        var daysUsed: Double
        if event["halfday"] as! Bool {
            if workingDaysCounter(from: event["startDate"] as! Date, until: event["endDate"] as! Date) == 1 {
                daysUsed = 0.5
            } else {
                daysUsed = 0
            }
        } else {
            daysUsed = workingDaysCounter(from: event["startDate"] as! Date, until: event["endDate"] as! Date)
        }
        let alertController = UIAlertController(title: "Knock it down", message: "You do not have enough days left", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "Carry On", style: .default, handler: nil)
        alertController.view.layoutIfNeeded()
        alertController.addAction(defaultAction)
        if event["type"] as! String == "Off" {
            let previousUsed = defaults.double(forKey: "offUsed")
            let offLeft = defaults.double(forKey: "off")
            if daysUsed > offLeft {
                navigationController?.present(alertController, animated: true, completion: nil)
                return
            }
            else {
                defaults.set(previousUsed + daysUsed, forKey: "offUsed")
                defaults.set(offLeft - daysUsed, forKey: "off")
                DataManager.shared.homeVC.createDataArray()
                DataManager.shared.homeVC.collectionView.reloadData()
            }
        }
        
        if event["type"] as! String == "Leave" {
            let previousUsed = defaults.double(forKey: "leaveUsed")
            let leaveLeft = defaults.double(forKey: "leave")
            if daysUsed > leaveLeft {
                navigationController?.present(alertController, animated: true, completion: nil)
                return
            }
            else {
                defaults.set(previousUsed + daysUsed, forKey: "leaveUsed")
                defaults.set(leaveLeft - daysUsed, forKey: "leave")
                DataManager.shared.homeVC.createDataArray()
                DataManager.shared.homeVC.collectionView.reloadData()
            }
        }
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "EventDetails", in: context)
        let newEntity = NSManagedObject(entity: entity!, insertInto: context)
        
        newEntity.setValue(event["title"] as Any?, forKey: "title")
        newEntity.setValue(event["type"] as Any?, forKey: "type")
        newEntity.setValue(event["halfday"] as Any?, forKey: "halfday")
        newEntity.setValue(event["startDate"] as Any?, forKey: "startDate")
        newEntity.setValue(event["endDate"] as Any?, forKey: "endDate")
        do {
            try context.save()
            print("saved")
        } catch{
            print("failed")
        }
        DataManager.shared.firstVC.getData()
        DataManager.shared.firstVC.tableView.reloadData()
        navigationController?.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addButton.isEnabled = false
        form +++ Section()
            <<< TextRow(){
                $0.tag = "title"
                $0.placeholder = "Title"
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }.cellUpdate{ cell,row in
                if !row.isValid{
                    self.disableButton()
                }
            }.onChange{ row in
                self.enableButton()
                }
            <<< PushRow<String>() {
                $0.tag = "type"
                $0.title = "Type"
                $0.selectorTitle = "Type"
                $0.options = ["Off","Leave","Duty","Exercise","Parade"]
                $0.value = "Off"    // initially selected
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }.onChange{ row in
                if row.value == nil {
                    self.disableButton()
                } else {
                    self.enableButton()
                }
            }
            
        +++ Section()
            <<< SwitchRow() {
                $0.title = "Half Day"
                $0.tag = "halfday"
                $0.value = false
            }.onChange{ row in
                let firstRow = self.form.rowBy(tag: "startDate") as! DateInlineRow
                let secondRow = self.form.rowBy(tag: "endDate") as! DateInlineRow
                if row.value! {
                    secondRow.value = firstRow.value
                }
            }
            <<< DateInlineRow(){
                $0.tag = "startDate"
                $0.title = "Starts"
                $0.value = date
            }.onChange{ row in
                let halfday = self.form.rowBy(tag: "halfday") as! SwitchRow
                let secondRow = self.form.rowBy(tag: "endDate") as! DateInlineRow
                if halfday.value ?? false {
                    secondRow.value = row.value!
                    secondRow.reload()
                }
                secondRow.minimumDate = row.value!
                if secondRow.value ?? date < row.value! {
                    secondRow.value = row.value!
                }
                secondRow.reload()
            }
            <<< DateInlineRow(){
                $0.tag = "endDate"
                $0.title = "Ends"
                $0.value = date
            }.onChange { row in
                let halfday = self.form.rowBy(tag: "halfday") as! SwitchRow
                let secondRow = self.form.rowBy(tag: "startDate") as! DateInlineRow
                if halfday.value ?? false {
                    secondRow.value = row.value!
                }
                if secondRow.value ?? date > row.value! {
                    secondRow.value = row.value!
                }
                secondRow.reload()
            }
    }
    
    func disableButton(){
        self.addButton.isEnabled = false
        self.addButton.setTitleColor(UIColor.opaqueSeparator, for: .disabled)
    }
    
    func enableButton(){
        self.addButton.isEnabled = true
        self.addButton.setTitleColor(UIColor.red, for: .normal)
    }
}
