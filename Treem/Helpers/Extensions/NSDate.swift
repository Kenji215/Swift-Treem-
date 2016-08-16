//
//  NSDate.swift
//  Treem
//
//  Created by Matthew Walker on 10/23/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

extension NSDate {

    //Takes in an ISO8601 string and turns it into an NSDate object
    convenience init?(iso8601String: String?) {
        if iso8601String == nil {
            self.init(timeIntervalSince1970: 0)
            
            return nil
        }
        
        let formatter = NSDateFormatter()

        formatter.dateFormat    = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"
        formatter.timeZone      = NSTimeZone(abbreviation: "UTC")
        formatter.calendar      = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)
        formatter.locale        = NSLocale(localeIdentifier: "en_US_POSIX")

        if let date = formatter.dateFromString(iso8601String!) {
            self.init(timeIntervalSince1970: date.timeIntervalSince1970)
        }
        else {
            self.init(timeIntervalSince1970: 0)
            
            return nil
        }
    }

    func daysFromDate(date: NSDate) -> Int {
        let calendar    = NSCalendar.currentCalendar()
        let date1       = calendar.startOfDayForDate(date)
        let date2       = calendar.startOfDayForDate(self)
        let components  = calendar.components(.Day, fromDate: date2, toDate: date1, options: [])
        
        return components.day
    }
    
    //Takes an NSDate object, and returns the value as an ISO8601 string
    func getISOFormattedString(timezone: NSTimeZone? = nil) -> String {
        let formatter = NSDateFormatter()
        
        formatter.dateFormat    = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"
        formatter.timeZone      = timezone ?? NSTimeZone(abbreviation: "UTC")
        formatter.calendar      = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)
        formatter.locale        = NSLocale(localeIdentifier: "en_US_POSIX")
        
        return formatter.stringFromDate(self)
    }
    
    func getRelativeDateFormattedString() -> String {
        let calendar    = NSCalendar.currentCalendar()
        let formatter   = NSDateFormatter()
        
        // check if date is in today
        if calendar.isDateInToday(self) {
            // format time
            formatter.dateFormat = "h:mm a"
            
            return "Today at " + formatter.stringFromDate(self)
        }
        // check if date is in yesterday
        else if calendar.isDateInYesterday(self) {
            // format time
            formatter.dateFormat = "h:mm a"
            
            return "Yesterday at " + formatter.stringFromDate(self)
        }
        // check if date is in last week
        else if self.daysFromDate(NSDate()) > 6 {
            formatter.dateStyle = .LongStyle    // i.e. "December 25, 2014"
            formatter.timeStyle = .ShortStyle   // i.e. "7:00 AM"
        }
        // get date from more than a week ago
        else {
            // if the date is less than a week ago show the day name and time
            formatter.dateFormat = "EEEE, h:mm a"
        }
        
        return formatter.stringFromDate(self)
    }
    
    func getRelativeShorthandDateFormattedString() -> String {
        let calendar    = NSCalendar.currentCalendar()
        let formatter   = NSDateFormatter()
        
        // check if date is in today
        if calendar.isDateInToday(self) {
            // format time
            formatter.dateFormat = "h:mm a"
            
            return "Today " + formatter.stringFromDate(self)
        }
        // check if date is in yesterday
        else if calendar.isDateInYesterday(self) {
            // format time
            formatter.dateFormat = "h:mm a"
            
            return "Yesterday " + formatter.stringFromDate(self)
        }
        // check if date is in last week
        else if self.daysFromDate(NSDate()) > 6 {
            formatter.dateFormat = "M/d/yy h:mm a"
        }
        // get date from more than a week ago
        else {
            // if the date is less than a week ago show the day name and time
            formatter.dateFormat = "E h:mm a"
        }
        
        return formatter.stringFromDate(self)
    }
}