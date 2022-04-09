//
//  Holidays.swift
//  ORD
//
//  Created by Joel Wong on 17/2/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import UIKit

struct Holiday {
    var name: String
    var date: String
}

func createHolidays() -> [Holiday]{
    let hol1 = Holiday(name: "New Year's Day", date: "01 Jan 2020")
    let hol2 = Holiday(name: "Chinese New Year", date: "25 Jan 2020")
    let hol3 = Holiday(name: "Good Friday", date: "10 Apr 2020")
    let hol4 = Holiday(name: "Labour Day", date: "01 May 2020")
    let hol5 = Holiday(name: "Vesak Day", date: "07 May 2020")
    let hol6 = Holiday(name: "Hari Raya Puasa", date: "24 May 2020")
    let hol7 = Holiday(name: "Hari Raya Haji", date: "31 Jul 2020")
    let hol8 = Holiday(name: "National Day", date: "09 Aug 2020")
    let hol9 = Holiday(name: "Deepavali", date: "14 Nov 2020")
    let hol10 = Holiday(name: "Christmas Day", date: "25 Dec 2020")
    return [hol1, hol2, hol3, hol4, hol5, hol6, hol7, hol8, hol9, hol10]
}

func upcomingHoliday(holidays: [Holiday]) -> Holiday {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMM yyyy"
    for holiday in holidays {
        if dateFormatter.date(from: holiday.date)! >= Date() {
            return holiday
        }
    }
    return holidays[0]
}
