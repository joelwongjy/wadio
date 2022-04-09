//
//  FloatingPanelViewController.swift
//  ORD
//
//  Created by Joel Wong on 17/2/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class SearchPanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    var event: [NSManagedObject] = []
    var holidays: [Holiday] = []
    var upcoming: Holiday? = nil
    var payday: String = ""
    var calendar = Calendar.current
    
    @objc func pastEvents(sender: UIButton!) {
        performSegue(withIdentifier: "pastEvents", sender: (Any).self)

    }
    func getData(){
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "EventDetails")
        request.predicate = NSPredicate(format: "endDate >= %@", end2 as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: true)]
        request.returnsObjectsAsFaults = false
        do {
            event = try context.fetch(request) as! [NSManagedObject]
        } catch{
            print("failed")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Reset for calculating new upcoming
        defaults.set(0, forKey: "upcomingOff")
        defaults.set(0, forKey: "upcomingLeave")
        
        // Generate events
        getData()
        holidays = createHolidays()
        upcoming = upcomingHoliday(holidays: holidays)
        payday = upcomingPayday()
        
        tableView.dataSource = self
        tableView.delegate = self
        DataManager.shared.firstVC = self
        
        // Check for Dark Mode
        if self.traitCollection.userInterfaceStyle == .dark {
            visualEffectView.effect = UIBlurEffect(style: .systemThinMaterialDark)
        }

    }
    
    // Check for Dark Mode change
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if self.traitCollection.userInterfaceStyle == .dark {
            visualEffectView.effect = UIBlurEffect(style: .systemThinMaterialDark)
        } else {
            visualEffectView.effect = UIBlurEffect(style: .extraLight)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return event.count + 2
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {

        guard section == 0 else { return nil }

        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44.0))
        let doneButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 34.0))
        // here is what you should add:
        doneButton.center = footerView.center

        doneButton.setTitle("View Past Events", for: .normal)
        doneButton.backgroundColor = .systemGray
        doneButton.layer.cornerRadius = 10.0
        doneButton.addTarget(self, action: #selector(pastEvents(sender:)), for: .touchUpInside)
        footerView.addSubview(doneButton)

        return footerView
    }
    
    // Generate Event Table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: EventCell!
        switch indexPath.row {
        case 0:
            // Holiday Cell
            cell = tableView.dequeueReusableCell(withIdentifier: "Holiday", for: indexPath) as? EventCell
            cell.holidayLabel.text = upcoming?.name
            cell.holidayDaysLabel.text = "\(daysCounter(from: date, until: dateFormatString(date: upcoming!.date)))"
            cell.holidayDateLabel.text = upcoming?.date
            cell.holidayIcon.image = UIImage(named: "holiday")
        case 1:
            // Payday Cell
            cell = tableView.dequeueReusableCell(withIdentifier: "PayDay", for: indexPath) as? EventCell
            cell.paydayDateLabel.text = payday
            cell.paydayDaysLabel.text = "\(daysCounter(from: date, until: dateFormatString(date: payday)))"
            cell.paydayIcon.image = UIImage(named: "payday")
        default:
            // Event Cell
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? EventCell
            let details = event[indexPath.row - 2]
            cell.iconImageView.image = UIImage(named: "like")
            cell.titleLabel.text = details.value(forKeyPath: "title") as? String
            let type = details.value(forKeyPath: "type") as! String
            let halfday = details.value(forKeyPath: "halfday") as? Bool
            let startDate = details.value(forKeyPath: "startDate") as? Date ?? date
            let endDate = details.value(forKeyPath: "endDate") as? Date ?? date
            let startDateStr = dateFormatDate(date: startDate)
            let endDateStr = dateFormatDate(date: endDate)
            cell.subTitleLabel.text = startDateStr + " - " + endDateStr
            if startDateStr == endDateStr{
                cell.subTitleLabel.text = startDateStr
            }
            if halfday! {
                cell.subTitleLabel.text = startDateStr + " (Half-day)"
            }
            if calendar.component(.day, from: startDate) <= calendar.component(.day, from: current) && startDate < current {
                cell.daysLabel.text = "\(daysCounter(from: date, until: endDate))"
            } else{
            cell.daysLabel.text = "\(daysCounter(from: date, until: startDate))"
            }
            
            var upcomingDays: Double
            
            // Calculate upcoming off and leave and set icons
            
            if halfday! {
                upcomingDays = 0.5
            } else {
                upcomingDays = workingDaysCounter(from: startDate, until: endDate)
            }
            if type == "Off"{
                cell.iconImageView.image = UIImage(named: "off")
                let upcoming = defaults.double(forKey: "upcomingOff")
                defaults.set(upcomingDays + upcoming, forKey: "upcomingOff")
            }
            if type == "Leave" {
                cell.iconImageView.image = UIImage(named: "leave")
                let upcoming = defaults.double(forKey: "upcomingLeave")
                defaults.set(upcomingDays + upcoming, forKey: "upcomingLeave")
            }
            if type == "Exercise"{
                cell.iconImageView.image = UIImage(named: "soldier")
            }
            if type == "Parade"{
                cell.iconImageView.image = UIImage(named: "parade")
            }
            if type == "Duty"{
                cell.iconImageView.image = UIImage(named: "duty")
            }
        }
    if indexPath.row == event.count + 1{
        DataManager.shared.homeVC.createDataArray()
        DataManager.shared.homeVC.collectionView.reloadData()
    }
    return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 || indexPath.row == 1 {
            return false
        }
        return true
    }
    
    // Segue to Edit Event
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "editEvent" {
            let navController = segue.destination as! UINavigationController
            let destination = navController.topViewController as! EditEventViewController
            guard let selectedCell = sender as? EventCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            guard let indexPath = tableView.indexPath(for: selectedCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            destination.eventName = event[indexPath.row - 2].value(forKeyPath: "title") as? String
            destination.type = event[indexPath.row - 2].value(forKeyPath: "type") as? String
            destination.halfday = event[indexPath.row - 2].value(forKeyPath: "halfday") as? Bool
            destination.startDate = event[indexPath.row - 2].value(forKeyPath: "startDate") as? Date
            destination.endDate = event[indexPath.row - 2].value(forKeyPath: "endDate") as? Date
        }
        
        if segue.identifier == "holidayCountdown" {
            guard let destination = segue.destination as? CountdownViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedCell = sender as? EventCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            destination.days = selectedCell.holidayDaysLabel.text!
            destination.name = selectedCell.holidayLabel.text!
        }
        
        if segue.identifier == "paydayCountdown" {
            guard let destination = segue.destination as? CountdownViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedCell = sender as? EventCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            destination.days = selectedCell.paydayDaysLabel.text!
            destination.name = "Pay Day"
        }
        
        if segue.identifier == "countdown" {
            guard let destination = segue.destination as? CountdownViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedCell = sender as? EventCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            guard let indexPath = tableView.indexPath(for: selectedCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            destination.startDate = event[indexPath.row - 2].value(forKeyPath: "startDate") as? Date
            destination.endDate = event[indexPath.row - 2].value(forKeyPath: "endDate") as? Date
            destination.days = selectedCell.daysLabel.text!
            destination.name = selectedCell.titleLabel.text!
        }
    }
    
    
    // Delete and Edit Event
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Delete Event
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, nil) in
            let details = self.event[indexPath.row - 2]
            
            // Calculate number of days to return
            let startDate = details.value(forKeyPath: "startDate") as? Date
            let endDate = details.value(forKeyPath: "endDate") as? Date
            var daysToReturn: Double
            if details.value(forKeyPath: "halfday") as! Bool {
                if workingDaysCounter(from: startDate!, until: endDate!) == 1 {
                    daysToReturn = 0.5
                } else {
                    daysToReturn = 0
                }
            } else {
                daysToReturn = workingDaysCounter(from: startDate!, until: endDate!)
            }
            // Return off or leave
            if details.value(forKeyPath: "type") as? String == "Off" {
                returnOff(days: daysToReturn)
                let upcoming = defaults.double(forKey: "upcomingOff")
                defaults.set(upcoming - daysToReturn, forKey: "upcomingOff")
            }
            if details.value(forKeyPath: "type") as? String == "Leave" {
                returnLeave(days: daysToReturn)
                let upcoming = defaults.double(forKey: "upcomingLeave")
                defaults.set(upcoming - daysToReturn, forKey: "upcomingLeave")
            }
            DataManager.shared.homeVC.createDataArray()
            DataManager.shared.homeVC.collectionView.reloadData()
            
            // Delete from CoreData
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            context.delete(self.event[indexPath.row - 2] as NSManagedObject)
            do {
                try context.save()
            } catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            } catch {
            // Add general error handle
            }
            self.event.remove(at: indexPath.row - 2)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            // Edit Event
            let edit = UIContextualAction(style: .normal, title: "Edit") { (action, view, nil) in
                self.performSegue(withIdentifier: "editEvent", sender: tableView.cellForRow(at: indexPath))
            }
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

class EventCell: UITableViewCell {
    @IBOutlet weak var holidayIcon: UIImageView!
    @IBOutlet weak var paydayIcon: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var daysLabel: UILabel!
    @IBOutlet weak var holidayLabel: UILabel!
    @IBOutlet weak var holidayDateLabel: UILabel!
    @IBOutlet weak var holidayDaysLabel: UILabel!
    @IBOutlet weak var paydayDateLabel: UILabel!
    @IBOutlet weak var paydayDaysLabel: UILabel!
}
