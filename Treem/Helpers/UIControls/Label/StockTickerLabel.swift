//
//  StockTickerLabel.swift
//  Treem
//
//  Created by Matthew Walker on 8/27/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class StockTickerLabel: UILabel {
    var showSymbolOnly = false
    
    private let positiveColor       = UIColor(red: 61/255, green: 150/255, blue: 0, alpha: 1)
    private let positiveColorLight  = UIColor(red: 141/255, green: 230/255, blue: 80/255, alpha: 1)
    
    private let negativeColor       = UIColor(red: 193/255, green: 46/255, blue: 35/255, alpha: 1)
    private let negativeColorLight  = UIColor(red: 193/255, green: 46/255, blue: 35/255, alpha: 1)
    
    private var initialTextColor: UIColor? = nil

    @IBInspectable
    var points: Int = 0 {
        didSet {
            self.updateLabelFromPoints()
        }
    }
    
    @IBInspectable
    var useLighterColors: Bool = false {
        didSet {
            self.updateLabelFromPoints()
        }
    }

    private func updateLabelFromPoints() {
        // update colors based on value set
        if(points < 0) {
            self.text = "▼" + (self.showSymbolOnly ? "" : String(points))
            self.textColor = self.useLighterColors ? self.negativeColorLight : self.negativeColor
        }
        else if(points == 0) {
            self.text = "" // don't show if no change
        }
        else {
            self.text = "▲" + (self.showSymbolOnly ? "" : String(points))
            self.textColor = self.useLighterColors ? self.positiveColorLight : self.positiveColor
        }
    }
}
