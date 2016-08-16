//
//  InAppNotifications.swift
//  Treem
//
//  Created by Daniel Sorrell on 3/11/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation


class InAppNotifications {
    
    static let sharedInstance = InAppNotifications()
    
    private var alerts : OrderedSet<Alert>? = nil
    
    func addInAppAlert(reason: Alert.Reasons, id: Int){
        if(self.alerts == nil){
            self.alerts = OrderedSet<Alert>()
        }
        
        let alert = Alert.init(reason: reason, id: id)
        
        alert.inAppAlert = true
        alert.alert_viewed = false
        alert.created = NSDate()
        alert.inAppAlert = true
        alert.inAppAlertId = NSUUID().UUIDString
        
        self.alerts!.insert(alert)
    }
    
    func removeInAppAlert(inAppAlertId: String){
        if let theAlerts = self.alerts {
            for alert in theAlerts {
                if (alert.inAppAlertId == inAppAlertId){
                    self.alerts!.remove(alert)
                }
            }
        }
    }
    
    func getInAppAlerts() -> OrderedSet<Alert>? { return alerts; }
}
