//
//  PagedSectionedTableViewController.swift
//  Treem
//
//  Created by Matthew Walker on 11/30/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

//import UIKit
//
//struct TableViewCollationSection {
//    var collationIndex  : Int = 0
//    var items           : [TableViewCellModelType] = []
//}
//
//class PagedSectionedTableViewController : PagedTableViewController {
//    let collation           = UILocalizedIndexedCollation.currentCollation()
//    
//    lazy var sections       : OrderedDictionary<Int, TableViewCollationSection> = [:]
//    var showSectionTitles   : Bool = true
//    
//    override func clearData() {
//        self.sections = [:]
//        
//        super.clearData()
//    }
//    
//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return self.sections.count
//    }
//    
//    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
//        if self.showSectionTitles && self.sections.count > 0 {
//            var titles : [String] = []
//            
//            for (_, section) in self.sections {
//                if let section = section {
//                    titles.append(self.collation.sectionTitles[section.collationIndex])
//                }
//            }
//            
//            return titles
//        }
//        
//        return nil
//    }
//    
//    override func setData<T where T: Hashable, T: TableViewCellModelType>(data: OrderedSet<T>) {
//        if ((data.count + self.totalRows) < 1) {
//            self.clearData()
//            
//            // show empty options
//            self.showEmptyView()
//        }
//        else {
//            if self.pageIndex <= self.initialPageIndex {
//                self.clearData()
//            }
//            
//            for item in data {
//                item.allRowsIndex = ++self.totalRows
//                
//                // get collation index
//                let index = self.collation.sectionForObject(item, collationStringSelector: "getSectionIndexIdentifier")
//                
//                // if section not stored
//                if self.sections[index] == nil {
//                    self.sections[index] = TableViewCollationSection(collationIndex: index, items: [])
//                }
//                
//                self.sections[index]?.items.append(item)
//            }
//        }
//    }
//    
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if let section = self.sections.getValueFromIndex(section) {
//            return section.items.count
//        }
//        
//        return 0
//    }
//    
//    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
//        return index
//    }
//    
//    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        if self.showSectionTitles {
//            if let section = self.sections.getValueFromIndex(section) {
//                if section.items.count > 0 {
//                    // add space for padding
//                    return "  " + self.collation.sectionTitles[section.collationIndex]
//                }
//            }
//        }
//        
//        return nil
//    }
//    
//    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
//        // get current index of row amongst all rows
//        if let section = self.sections.getValueFromIndex(indexPath.section) {
//            if(section.items.indices.contains(indexPath.row)){
//                super.tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: NSIndexPath(forRow: section.items[indexPath.row].allRowsIndex, inSection: 0))
//            }
//        }
//    }
//}
