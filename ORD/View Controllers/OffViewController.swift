//
//  OffViewController.swift
//  ORD
//
//  Created by Joel Wong on 21/3/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import UIKit
import CoreData

class OffViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var event: [NSManagedObject] = []
    var offSource: [NSManagedObject] = []
    var offDays: Double = 0
    var offUsed: Double = 0
    
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var offTableView: UITableView!
    @IBOutlet weak var pastOffTableView: UITableView!
    @IBOutlet weak var offView: UIView!
    @IBOutlet weak var historicalOff: UILabel!
    @IBOutlet weak var offCount: UILabel!
    @IBOutlet weak var offSourceHeight: NSLayoutConstraint!
    @IBOutlet weak var pastOffHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getData()
        getOffs()
        displayInfo()
                
        pastOffTableView.dataSource = self
        pastOffTableView.delegate = self
        offTableView.delegate = self
        offTableView.dataSource = self
        DataManager.shared.offVC = self
    }
    
    func displayInfo(){
        offDays = defaults.double(forKey: "off")
        offUsed = defaults.double(forKey: "offUsed")
        offCount.text = String(format: "%g", offDays)
        historicalOff.text = "Historical Off: \(String(format: "%g", offDays + offUsed))"
        if offSource.count < 3 {
            offSourceHeight.constant = CGFloat(250)
        } else {
            offSourceHeight.constant = CGFloat(offSource.count*60 + 80)
        }
        if event.count == 0 {
            pastOffHeight.constant = CGFloat(250)
        } else {
            pastOffHeight.constant = CGFloat(event.count*60+50)
        }
    }
    
    func getData(){
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "EventDetails")
        request.predicate = NSPredicate(format: "endDate < %@ AND type == 'Off'", end2 as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: false)]
        request.returnsObjectsAsFaults = false
        do {
            event = try context.fetch(request) as! [NSManagedObject]
        } catch{
            print("failed")
        }
    }
    
    func getOffs(){
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "OffSource")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.returnsObjectsAsFaults = false
        do {
            offSource = try context.fetch(request) as! [NSManagedObject]
        } catch{
            print("failed")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case offTableView:
            if offSource.count == 0 {
                self.offTableView.setEmptyMessage("Ask your Encik for off")
            } else {
                self.offTableView.restore()
            }
            return offSource.count
            
        case pastOffTableView:
            if event.count == 0 {
                self.pastOffTableView.setEmptyMessage("No off cleared")
            } else {
                self.pastOffTableView.restore()
            }
            return event.count

        default:
            fatalError("Invalid table")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case offTableView:
            var cell: OffSourceCell!
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? OffSourceCell
            let details = offSource[indexPath.row]
            cell.offSourceTitle.text = details.value(forKeyPath: "title") as? String
            let offDays = details.value(forKeyPath: "days") as! Float
            cell.offDays.text = String(format: "%g", offDays)
            let addDate = details.value(forKeyPath: "date") as! Date
            cell.addDate.text = dateFormatDate(date: addDate)
            return cell
        
        case pastOffTableView:
            var cell2: OffCell!
            cell2 = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? OffCell
            let details = event[indexPath.row]
            cell2.offTitle.text = details.value(forKeyPath: "title") as? String
            let halfday = details.value(forKeyPath: "halfday") as! Bool
            let startDate = details.value(forKeyPath: "startDate") as? Date ?? date
            let endDate = details.value(forKeyPath: "endDate") as? Date ?? date
            let startDateStr = dateFormatDate(date: startDate)
            let endDateStr = dateFormatDate(date: endDate)
            cell2.offDates.text = startDateStr + " - " + endDateStr
            if startDateStr == endDateStr || halfday{
                cell2.offDates.text = startDateStr
            }
            if halfday {
                cell2.daysPast.text = "0.5"
            } else {
                cell2.daysPast.text = String(format: "%g", workingDaysCounter(from: startDate, until: endDate))
            }
            return cell2
        default:
            fatalError("Invalid table")
        }
    }
        
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch tableView {
        case offTableView:
            // Delete Event
            let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, nil) in
                let details = self.offSource[indexPath.row]
                let days = details.value(forKeyPath: "days") as? Double
                removeOff(days: days!)
                let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                context.delete(self.offSource[indexPath.row] as NSManagedObject)
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save \(error), \(error.userInfo)")
                } catch {
                // Add general error handle
                }
                self.offSource.remove(at: indexPath.row)
                self.offTableView.deleteRows(at: [indexPath], with: .automatic)
                self.displayInfo()
                DataManager.shared.homeVC.createDataArray()
                DataManager.shared.homeVC.collectionView.reloadData()
            }
        return UISwipeActionsConfiguration(actions: [delete])
            
        case pastOffTableView:
            // Delete Event
            let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, nil) in
                let details = self.event[indexPath.row]
                let startDate = details.value(forKeyPath: "startDate") as? Date
                let endDate = details.value(forKeyPath: "endDate") as? Date
                var daysToReturn: Double
                if details.value(forKeyPath: "halfday") as! Bool {
                    daysToReturn = 0.5
                } else {
                    daysToReturn = workingDaysCounter(from: startDate!, until: endDate!)
                }
                if details.value(forKeyPath: "type") as? String == "Off" {
                    returnOff(days: daysToReturn)
                }
                let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                context.delete(self.event[indexPath.row] as NSManagedObject)
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save \(error), \(error.userInfo)")
                } catch {
                // Add general error handle
                }
                self.event.remove(at: indexPath.row)
                self.pastOffTableView.deleteRows(at: [indexPath], with: .automatic)
                self.displayInfo()
                DataManager.shared.homeVC.createDataArray()
                DataManager.shared.homeVC.collectionView.reloadData()
            }
            
            // Edit Event
            let edit = UIContextualAction(style: .normal, title: "Edit") { (action, view, nil) in
                self.performSegue(withIdentifier: "editEvent", sender: tableView.cellForRow(at: indexPath))
                self.displayInfo()
                DataManager.shared.homeVC.createDataArray()
                DataManager.shared.homeVC.collectionView.reloadData()
            }

        return UISwipeActionsConfiguration(actions: [delete, edit])
        default:
            fatalError("Invalid table")
        }
    }
        
    
    // Segue to Edit Event
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "editEvent" {
            let navController = segue.destination as! UINavigationController
            let destination = navController.topViewController as! EditEventViewController
            //guard let destination = segue.destination as? EditEventViewController else {
                //fatalError("Unexpected destination: \(segue.destination)")
            //}
            guard let selectedCell = sender as? OffCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            guard let indexPath = pastOffTableView.indexPath(for: selectedCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            destination.eventName = event[indexPath.row].value(forKeyPath: "title") as? String
            destination.type = event[indexPath.row].value(forKeyPath: "type") as? String
            destination.halfday = event[indexPath.row].value(forKeyPath: "halfday") as? Bool
            destination.startDate = event[indexPath.row].value(forKeyPath: "startDate") as? Date
            destination.endDate = event[indexPath.row].value(forKeyPath: "endDate") as? Date
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

class OffCell: UITableViewCell {
    @IBOutlet weak var offTitle: UILabel!
    @IBOutlet weak var offDates: UILabel!
    @IBOutlet weak var daysPast: UILabel!
}

class OffSourceCell: UITableViewCell {
    @IBOutlet weak var offSourceTitle: UILabel!
    @IBOutlet weak var offDays: UILabel!
    @IBOutlet weak var addDate: UILabel!
}
