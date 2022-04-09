//
//  DateFunctions.swift
//  ORD
//
//  Created by Joel Wong on 29/1/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import Foundation
import UIKit

let date = Date()
let current = date.addingTimeInterval(8*3600)
let calendar = Calendar.current
let defaults = UserDefaults.standard
let end = calendar.date(bySettingHour: 7, minute: 59, second: 59, of: date)!
let end2 = end.addingTimeInterval(-8*3600)

func dateFormatDate(date : Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMM yyyy"
    return dateFormatter.string(from: date)
}

func dateFormatString(date: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMM yyyy"
    return dateFormatter.date(from: date)!
}

func upcomingPayday() -> String {
    let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    for month in months {
        let paydayString = "10 \(month) \(calendar.component(.year, from:date))"
        var payday = dateFormatString(date: paydayString)
        if payday >= date {
            while calendar.isDateInWeekend(payday) == true{
                payday = calendar.date(byAdding: .day, value: -1, to: payday)!
            }
            if isPublicHoliday(day: payday) == true{
                payday = calendar.date(byAdding: .day, value: -1, to: payday)!
            }
            return dateFormatDate(date: payday)
        }
    }
    return "10 Feb 2020"
}

func isPublicHoliday(day: Date) -> Bool {
    let day = dateFormatDate(date: day)
    let holidays = createHolidays()
    for holiday in holidays {
        if holiday.date == day {
            return true
        }
    }
    return false
}

func isDayPassed(endDate: Date) -> Bool {
    let todaysDate = date.addingTimeInterval(8 * 3600)
    let days = calendar.dateComponents([.day], from: todaysDate, to: endDate)
    let daysCount = days.day!
    if daysCount < 0{
        return true
    }
    return false
}

func daysCounter(from startDate: Date, until endDate: Date) -> Int {
    let todaysDate = startDate.addingTimeInterval(8 * 3600)
    let end1 = calendar.date(byAdding: .day, value: 1, to: endDate)!
    let end2 = calendar.date(bySettingHour: 7, minute: 59, second: 59, of: end1)!
    let days = calendar.dateComponents([.day], from: todaysDate, to: end2)
    let daysCount = days.day!
    return daysCount
}

func workingDaysCounter(from startDate: Date, until endDate: Date) -> Double {
    var weekends = 0
    var workingDays = 0
    var holidays = 0
    var todaysDate = startDate.addingTimeInterval(8 * 3600)
    let end1 = calendar.date(byAdding: .day, value: 1, to: endDate)!
    let end2 = calendar.date(bySettingHour: 7, minute: 59, second: 59, of: end1)!
    while todaysDate < end2 {
        if calendar.isDateInWeekend(todaysDate.addingTimeInterval(-8 * 3600)) {
            weekends += 1
        } else if isPublicHoliday(day: todaysDate) == true{
            holidays += 1
        }
        else {
            workingDays += 1
        }
        todaysDate = calendar.date(byAdding: .day, value: 1, to: todaysDate)!
    }
    return Double(workingDays)
}


func progressCounter(from startDate: Date, until endDate: Date) -> Double {
    var serviceDays:Int? = nil
    let serviceTerm = defaults.integer(forKey: "months")
    
    if serviceTerm == 22 {
        guard let enlistmentDate = calendar.date(byAdding: .month, value: -22, to: endDate) else {
            return 1
        }
        serviceDays = daysCounter(from: enlistmentDate, until: endDate)
    }
    else {
        guard let enlistmentDate = calendar.date(byAdding: .month, value: -24, to: endDate) else {
            return 1
        }
        serviceDays = daysCounter(from: enlistmentDate, until: endDate)
    }
    let progress: Double = Double(serviceDays! - (daysCounter(from: startDate, until: endDate))) / Double(serviceDays!)
    return progress
}

func calculateLeave(endDate: Date) {
    let leaveUsed = defaults.integer(forKey: "leaveUsed")
    let components = Calendar.current.dateComponents([.year], from: date)
    let serviceTerm = defaults.integer(forKey: "months")
    var enlistmentDate: Date = date
    if serviceTerm == 22 {
        enlistmentDate = calendar.date(byAdding: .month, value: -22, to: endDate)!
    }
    else {
        enlistmentDate = calendar.date(byAdding: .month, value: -24, to: endDate)!
    }
    guard let startDateOfYear = Calendar.current.date(from: components) else { return }
    if calendar.component(.year, from: enlistmentDate) == calendar.component(.year, from: date){
        let leaveCount = ceil((Double(365) - Double(daysCounter(from: startDateOfYear, until: enlistmentDate))) / Double(365) * 14)
        defaults.set(Int(leaveCount) - leaveUsed, forKey: "leave")
    }
    else if calendar.component(.year, from: endDate) != calendar.component(.year, from: date) {
        defaults.set(14 - leaveUsed, forKey: "leave")
    }
    else {
        let leaveCount = ceil(Double(daysCounter(from: startDateOfYear, until: endDate)) / Double(365) * 14)
        defaults.set(Int(leaveCount) - leaveUsed, forKey: "leave")
    }
}

func returnLeave(days: Double) {
    let previousDays = defaults.double(forKey: "leave")
    let previousUsed = defaults.double(forKey: "leaveUsed")
    defaults.set(days + previousDays, forKey: "leave")
    defaults.set(previousUsed - days, forKey: "leaveUsed")
}

func returnOff(days: Double) {
    let previousDays = defaults.double(forKey: "off")
    let previousUsed = defaults.double(forKey: "offUsed")
    defaults.set(days + previousDays, forKey: "off")
    defaults.set(previousUsed - days, forKey: "offUsed")
}

func removeOff(days: Double) {
    let previousDays = defaults.double(forKey: "off")
    defaults.set(previousDays - days, forKey: "off")
}

class DataManager {

    static let shared = DataManager()
    var homeVC = ViewController()
    var firstVC = SearchPanelViewController()
    var leaveVC = LeaveViewController()
    var offVC = OffViewController()
    var pastVC = PastEventsViewController()
}

extension UITableView {

    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        messageLabel.textColor = .systemGray
        messageLabel.sizeToFit()

        self.backgroundView = messageLabel
        self.separatorStyle = .none
    }

    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}
