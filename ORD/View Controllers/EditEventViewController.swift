//
//  EditEventViewController.swift
//  ORD
//
//  Created by Joel Wong on 20/2/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import UIKit
import Eureka
import CoreData

class EditEventViewController: FormViewController {
    
    var toEdit : [NSManagedObject] = []
    var eventName: String?
    var type: String?
    var halfday: Bool?
    var startDate: Date?
    var endDate: Date?
    let defaults = UserDefaults.standard
    var leaveToReturn: Double = 0
    var offToReturn: Double = 0
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }

    @IBAction func saveButton(_ sender: UIButton) {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "EventDetails")
        request.predicate = NSPredicate(format: "title == %@ AND type == %@ AND startDate = %@ AND endDate = %@", eventName!, type!, startDate! as NSDate, endDate! as NSDate)
        request.returnsObjectsAsFaults = false
        do {
            toEdit = try context.fetch(request) as! [NSManagedObject]
        } catch{
            print("failed")
        }
        let alertController = UIAlertController(title: "Knock it down", message: "You do not have enough days left", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "Carry On", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        
        let editedEvent = form.values()
        let newStartDate = editedEvent["startDate"] as! Date
        let newEndDate = editedEvent["endDate"] as! Date

        if type == "Leave" {
            if halfday!{
                if workingDaysCounter(from: startDate!, until: endDate!) == 1 {
                    leaveToReturn = 0.5
                } else {
                    leaveToReturn = 0
                }
            } else{
                leaveToReturn = workingDaysCounter(from: startDate!, until: endDate!)
            }
        }
        
        if type == "Off" {
            if halfday!{
                if workingDaysCounter(from: startDate!, until: endDate!) == 1 {
                    offToReturn = 0.5
                } else {
                    offToReturn = 0
                }
            } else{
            offToReturn = workingDaysCounter(from: startDate!, until: endDate!)
            }
        }
        
        var daysUsed: Double
        if editedEvent["halfday"] as! Bool {
            if workingDaysCounter(from: newStartDate, until: newEndDate) == 1 {
                daysUsed = 0.5
            } else {
                daysUsed = 0
            }
        } else {
            daysUsed = workingDaysCounter(from: newStartDate, until: newEndDate)
        }
        
        if editedEvent["type"] as! String == "Leave" {
            let previousUsed = defaults.double(forKey: "leaveUsed")
            let leaveLeft = defaults.double(forKey: "leave")
            if daysUsed > leaveLeft + leaveToReturn {
                navigationController?.present(alertController, animated: true, completion: nil)
                return
            }
            defaults.set(previousUsed + daysUsed, forKey: "leaveUsed")
            defaults.set(leaveLeft - daysUsed, forKey: "leave")
            DataManager.shared.leaveVC.getData()
            DataManager.shared.leaveVC.tableView.reloadData()
        }
        
        if editedEvent["type"] as! String == "Off" {
            let previousUsed = defaults.double(forKey: "offUsed")
            let offLeft = defaults.double(forKey: "off")
            if daysUsed > offLeft + offToReturn {
                navigationController?.present(alertController, animated: true, completion: nil)
                return
            }
            defaults.set(previousUsed + daysUsed, forKey: "offUsed")
            defaults.set(offLeft - daysUsed, forKey: "off")
            DataManager.shared.offVC.getData()
            DataManager.shared.offVC.pastOffTableView.reloadData()
        }
        if type == "Leave" {
            returnLeave(days: leaveToReturn)
            DataManager.shared.leaveVC.getData()
            DataManager.shared.leaveVC.tableView.reloadData()
        }
        if type == "Off" {
            returnOff(days: offToReturn)
            DataManager.shared.offVC.getData()
            DataManager.shared.offVC.pastOffTableView.reloadData()
        }
        toEdit[0].setValue(editedEvent["title"] as Any?, forKey: "title")
        toEdit[0].setValue(editedEvent["type"] as Any?, forKey: "type")
        toEdit[0].setValue(editedEvent["halfday"] as Any?, forKey: "halfday")
        toEdit[0].setValue(editedEvent["startDate"] as Any?, forKey: "startDate")
        toEdit[0].setValue(editedEvent["endDate"] as Any?, forKey: "endDate")
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
        saveButton.isEnabled = false
        form +++ Section()
            <<< TextRow(){
                $0.tag = "title"
                $0.placeholder = "Title"
                $0.value = eventName
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }.cellUpdate{ cell,row in
                if !row.isValid {
                    self.disableButton()
                }
            }.onChange{ row in
                if row.value == self.eventName!{
                    self.disableButton()
                }
                else{
                    self.enableButton()
                }
                }
            <<< PushRow<String>() {
                $0.tag = "type"
                $0.title = "Type"
                $0.selectorTitle = "Type"
                $0.options = ["Off","Leave","Duty","Exercise","Parade"]
                $0.value = "\(String(describing: type!))"    // initially selected
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnDemand
            }.cellUpdate{ cell,row in
                self.form.validate()
                }.onChange{ row in
                    if row.value == self.type! || row.value == nil{
                    self.disableButton()
                }
                else{
                    self.enableButton()
                }
            }
            
        +++ Section()
            <<< SwitchRow() {
                $0.title = "Half Day"
                $0.tag = "halfday"
                $0.value = halfday
            }.onChange{ row in
                if row.value == self.halfday!{
                     self.disableButton()
                 }
                 else{
                     self.enableButton()
                 }
                let firstRow = self.form.rowBy(tag: "startDate") as! DateInlineRow
                let secondRow = self.form.rowBy(tag: "endDate") as! DateInlineRow
                if row.value! {
                    secondRow.value = firstRow.value
                }
            }
            <<< DateInlineRow(){
                $0.tag = "startDate"
                $0.title = "Starts"
                $0.value = startDate
                }.onChange{ row in
                    if row.value == self.startDate!{
                        self.disableButton()
                    }
                    else{
                        self.enableButton()
                    }
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
                $0.value = endDate
            }.onChange { row in
                if row.value == self.endDate!{
                    self.disableButton()
                } else{
                    self.enableButton()
                }
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
        self.saveButton.isEnabled = false
        self.saveButton.setTitleColor(UIColor.opaqueSeparator, for: .disabled)
    }

    func enableButton(){
        self.saveButton.isEnabled = true
        self.saveButton.setTitleColor(UIColor.red, for: .normal)
    }
}
