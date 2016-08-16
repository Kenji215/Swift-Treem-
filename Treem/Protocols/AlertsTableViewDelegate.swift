//
//  AlertsTableViewDelegate
//  Treem
//
//  Created by Matthew Walker on 3/17/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

protocol AlertsTableViewDelegate {
    func selectedAlertsUpdated(alerts: Dictionary<NSIndexPath,Alert>)
    
//    func alternateAlertViewIsDirty(isDirty: Bool)
}