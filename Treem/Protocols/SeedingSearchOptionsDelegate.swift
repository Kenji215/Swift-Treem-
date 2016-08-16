//
//  SearchOptionsDelegate.swift
//  Treem
//
//  Created by Matthew Walker on 11/20/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

protocol SeedingSearchOptionsDelegate {
    var searchOptions: SeedingSearchOptions { get }
    
    // called when search options are dismissed
    func didDismissSearchOptions (optionsChanged: Bool, options: SeedingSearchOptions)

}