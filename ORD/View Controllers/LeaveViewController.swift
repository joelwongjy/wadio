//
//  LeaveViewController.swift
//  ORD
//
//  Created by Joel Wong on 20/3/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import UIKit
import CoreData

class LeaveViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet weak var leaveLeft: UILabel!
    @IBOutlet weak var leaveCount: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var event: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getData()
        displayInfo()
        tableView.dataSource = self
        tableView.delegate = self
        DataManager.shared.leaveVC = self
    }
    
    func displayInfo() {
        let leave = defaults.double(forKey: "leave")
        let leaveUsed = defaults.double(forKey: "leaveUsed")
        leaveLeft.text = String(format: "%g", leave)
        let totalLeave = String(format: "%g", leave + leaveUsed)
        leaveCount.text = "of \(totalLeave) left"
    }
    
    func getData(){
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "EventDetails")
        request.predicate = NSPredicate(format: "endDate < %@ AND type == 'Leave'", end2 as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: false)]
        request.returnsObjectsAsFaults = false
        do {
            event = try context.fetch(request) as! [NSManagedObject]
        } catch{
            print("failed")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if event.count == 0 {
            self.tableView.setEmptyMessage("Saving till December?")
        } else {
            self.tableView.restore()
        }
        return event.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: LeaveCell!
        cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? LeaveCell
        let details = event[indexPath.row]
        cell.leaveTitle.text = details.value(forKeyPath: "title") as? String
        let halfday = details.value(forKeyPath: "halfday") as! Bool
        let startDate = details.value(forKeyPath: "startDate") as? Date ?? date
        let endDate = details.value(forKeyPath: "endDate") as? Date ?? date
        let startDateStr = dateFormatDate(date: startDate)
        let endDateStr = dateFormatDate(date: endDate)
        cell.leaveDates.text = startDateStr + " - " + endDateStr
        
        if startDateStr == endDateStr || halfday{
            cell.leaveDates.text = startDateStr
        }
        if halfday {
            cell.daysPast.text = "0.5"
        } else {
            cell.daysPast.text = String(format: "%g", workingDaysCounter(from: startDate, until: endDate))
        }
        return cell
    }
            
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
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
                if details.value(forKeyPath: "type") as? String == "Leave" {
                    returnLeave(days: daysToReturn)
                    DataManager.shared.homeVC.createDataArray()
                    DataManager.shared.homeVC.collectionView.reloadData()
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
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.displayInfo()
            }
            
            // Edit Event
            let edit = UIContextualAction(style: .normal, title: "Edit") { (action, view, nil) in
                self.performSegue(withIdentifier: "editEvent", sender: tableView.cellForRow(at: indexPath))
                self.displayInfo()
            }
        return UISwipeActionsConfiguration(actions: [delete, edit])
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
            guard let selectedCell = sender as? LeaveCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            guard let indexPath = tableView.indexPath(for: selectedCell) else {
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

class LeaveCell: UITableViewCell {
    @IBOutlet weak var leaveTitle: UILabel!
    @IBOutlet weak var leaveDates: UILabel!
    @IBOutlet weak var daysPast: UILabel!
}
