//
//  PastEventsViewController.swift
//  ORD
//
//  Created by Joel Wong on 21/4/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import UIKit
import CoreData

class PastEventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var event: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getData()
        DataManager.shared.pastVC = self
    }
    
    func getData(){
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "EventDetails")
        request.predicate = NSPredicate(format: "endDate < %@ AND type != 'Leave' AND type != 'Off'", end2 as NSDate)
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
            self.tableView.setEmptyMessage("No Past Events")
        } else {
            self.tableView.restore()
        }
        return event.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: PastEventCell!
        cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? PastEventCell
        let details = event[indexPath.row]
        cell.eventTitle.text = details.value(forKeyPath: "title") as? String
        let type = details.value(forKeyPath: "type") as! String
        let halfday = details.value(forKeyPath: "halfday") as! Bool
        let startDate = details.value(forKeyPath: "startDate") as? Date ?? date
        let endDate = details.value(forKeyPath: "endDate") as? Date ?? date
        let startDateStr = dateFormatDate(date: startDate)
        let endDateStr = dateFormatDate(date: endDate)
        cell.eventDates.text = startDateStr + " - " + endDateStr
        
        if startDateStr == endDateStr || halfday{
            cell.eventDates.text = startDateStr
        }
        cell.daysPast.text = "\(Int(workingDaysCounter(from: endDate, until: date)))"
        
        if type == "Exercise"{
            cell.eventImage.image = UIImage(named: "soldier")
        }
        if type == "Parade"{
            cell.eventImage.image = UIImage(named: "parade")
        }
        if type == "Duty"{
            cell.eventImage.image = UIImage(named: "parade")
        }
        return cell
    }
        
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            // Delete Event
            let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, nil) in
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
            }
            
            // Edit Event
            let edit = UIContextualAction(style: .normal, title: "Edit") { (action, view, nil) in
                self.performSegue(withIdentifier: "editEvent", sender: tableView.cellForRow(at: indexPath))
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
            guard let selectedCell = sender as? PastEventCell else {
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

class PastEventCell: UITableViewCell {
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventDates: UILabel!
    @IBOutlet weak var daysPast: UILabel!
}
