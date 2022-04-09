//
//  popupvc.swift
//  ordtest
//
//  Created by Joel Wong on 8/1/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import UIKit

class PopUpVC: UIViewController{
    
    @IBOutlet var ordDatePicker: UIDatePicker!

    @IBAction func ordDateChange(_ sender: Any) {
        let ordDate = ordDatePicker.date
        defaults.set(ordDate, forKey: "ordDate")
    }
    
    override func viewDidLoad() {
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = true
        ordDatePicker.minimumDate = date
        ordDatePicker.maximumDate = calendar.date(byAdding: .year, value: 10, to: date)
    }
}

class PopDateViewController: UIViewController {
    
    @IBOutlet weak var popDatePicker: UIDatePicker!
    
    @IBAction func popDateChange(_ sender: Any) {
        let popDate = popDatePicker.date
        defaults.set(popDate, forKey: "popDate")
    }
    override func viewDidLoad() {
        popDatePicker.minimumDate = calendar.date(byAdding: .year, value: -2, to: date)
        popDatePicker.maximumDate = calendar.date(byAdding: .year, value: 10, to: date)
    }
    
}

class ServiceTermViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate{
    
    var pickerOptions: [String] = [String]()

    @IBOutlet weak var serviceTermPicker: UIPickerView!
    
    @IBAction func setupDone(_ sender: Any) {
        calculateLeave(endDate: defaults.value(forKey: "ordDate") as? Date ?? date)
        defaults.set(calendar.component(.year, from: date), forKey: "year")
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let valueSelected = pickerOptions[row]
        if valueSelected == "22 Months" {
            defaults.set(22, forKey: "months")
        }
        else {
            defaults.set(24, forKey: "months")
        }
    }
    
    override func viewDidLoad() {
        pickerOptions = ["22 Months", "24 Months"]
    }
}
