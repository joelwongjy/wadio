//
//  AddOffViewController.swift
//  ORD
//
//  Created by Joel Wong on 16/4/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import UIKit
import Eureka
import CoreData

class AddOffViewController: FormViewController{
    let defaults = UserDefaults.standard
    let today = date.addingTimeInterval(8*3600)

    @IBOutlet weak var addButton: UIButton!
    @IBAction func cancelEvent(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }
    
    @IBAction func addEvent(_ sender: Any) {
        let newOff = form.values()
        let previousOff = defaults.double(forKey: "off")
        defaults.set(newOff["Days"] as! Double + previousOff, forKey: "off")
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "OffSource", in: context)
        let newEntity = NSManagedObject(entity: entity!, insertInto: context)
        
        newEntity.setValue(newOff["title"] as Any?, forKey: "title")
        newEntity.setValue(newOff["Days"] as Any?, forKey: "days")
        newEntity.setValue(newOff["date"] as Any?, forKey: "date")
        do {
            try context.save()
            print("saved")
        } catch{
            print("failed")
        }
        DataManager.shared.offVC.getOffs()
        DataManager.shared.offVC.displayInfo()
        DataManager.shared.offVC.offTableView.reloadData()
        DataManager.shared.homeVC.createDataArray()
        DataManager.shared.homeVC.collectionView.reloadData()
        navigationController?.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //addButton.isEnabled = false
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
            
        +++ Section()
            <<< DateInlineRow(){
                $0.title = "Date Earned"
                $0.tag = "date"
                $0.value = date
                $0.minimumDate = calendar.date(byAdding: .year, value: -2, to: date)
                $0.maximumDate = calendar.date(byAdding: .year, value: 2, to: date)
            }
            <<< StepperRow(){
                $0.title = "Days"
                $0.tag = $0.title
                $0.value = 0.5
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
        }.cellSetup { cell, row in
            cell.stepper.maximumValue = 20.0
            cell.stepper.minimumValue = 0.5
            cell.stepper.stepValue = 0.5
        }.cellUpdate{ cell,row in
            if !row.isValid{
                self.disableButton()
            }
        }.onChange{ row in
            self.enableButton()
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

