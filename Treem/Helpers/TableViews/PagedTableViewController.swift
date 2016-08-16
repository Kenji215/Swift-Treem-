//
//  PagedTableView.swift
//  Treem
//
//  Created by Matthew Walker on 11/25/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

protocol TableViewCellModelType: AnyObject    {
    var allRowsIndex : Int { get set }   // independent of sections
    
    func getSectionIndexIdentifier() -> String  // method to call when determining sorting for current collation
}

extension TableViewCellModelType {
    func getSectionIndexIdentifier() -> String {
        return ""
    }
}

class PagedTableViewController: UITableViewController {
    let initialPageIndex            : Int = 1
    private(set) var pageIndex      : Int = 1
    
    private var isRefreshing        : Bool = false
    
    private lazy var errorViewController         = ErrorViewController.getStoryboardInstance()
    private lazy var loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    // settings
    var pageSize : Int = 20 {
        didSet {
            // update once when property set, use truncated property
            self.getNextPageRowCount = Int(Double(self.pageSize) * 0.5)
        }
    }
    
    var totalRows               : Int = 0
    var useRefreshControl       : Bool = false {
        didSet {
            if self.useRefreshControl {
                let refreshControl  = UIRefreshControl()
                
                refreshControl.backgroundColor  = UIColor.clearColor()
                refreshControl.tintColor        = self.activityIndicatorColor
                refreshControl.addTarget(self, action: #selector(PagedTableViewController.refresh(_:)), forControlEvents: .ValueChanged)
                
                self.refreshControl = refreshControl
            }
            else {
                self.refreshControl = nil
            }
        }
    }
    var pagedDataCall           : ((page: Int, pageSize: Int) -> ())? = nil
    var getNextPageRowCount     : Int = 10 // call next page after number of rows
    var items                   : [TableViewCellModelType] = []
    var emptyText               : String?
    var emptyButtonTitle        : String?
    var emptyRemoveViewOnRecover: Bool = false
    var emptyRecover            : (()->())? = nil
    var isLoadingData           : Bool = false
    var scrollingEnabled        : Bool = true
    var activityIndicatorColor  : UIColor = AppStyles.sharedInstance.darkGrayColor
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        // if paged data call provided
        if let pagedDataCall = self.pagedDataCall where !self.isRefreshing {
            let zeroBasedPageIndex          = self.pageIndex - 1
            let allRowsBeforeCurrentPage    = zeroBasedPageIndex * self.pageSize
            
            // check if another page call needed and if meeting the row that triggers next page call
            if self.totalRows >= allRowsBeforeCurrentPage + self.pageSize &&
                indexPath.row > allRowsBeforeCurrentPage + self.getNextPageRowCount
            {
                // increase to next page
                self.pageIndex += 1
                
                #if DEBUG
                    print("Loading page: \(self.pageIndex), results \((self.pageIndex - 1) * self.pageSize)-\(((self.pageIndex - 1) * self.pageSize) + self.pageSize)")
                #endif
                
                pagedDataCall(page: self.pageIndex, pageSize: self.pageSize)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // disable delayed content touches
        for view in self.tableView.subviews {
            if let scroll = view as? UIScrollView {
                scroll.delaysContentTouches = false
            }
        }
        
        // apply common styles
        self.tableView.sectionIndexColor        = AppStyles.sharedInstance.tintColor
        self.tableView.separatorColor           = AppStyles.sharedInstance.dividerColor
        
        // zeroing footer removes trailing empty cells
        self.clearTableFooter()
    }
    
    func cancelLoadingMask() {
        if self.isRefreshing {
            self.refreshControl?.endRefreshing()
            self.isRefreshing = false
        }
        else {
            self.loadingMaskViewController.cancelLoadingMask(nil)
            self.tableView.scrollEnabled = self.scrollingEnabled
        }
        
        self.clearTableFooter()
    }
    
    func clearData() {
        self.items      = []
        self.totalRows  = 0
        
        self.resetPageIndex()
        
        self.hideEmptyView()
    }
    
    func clearTableFooter() {
        self.tableView.tableFooterView = UIView()
    }
    
    func removeItem(indexRow: Int){
        // make sure this index exists before we remove it
        if(indexRow < self.items.count){
            self.items.removeAtIndex(indexRow)
            self.totalRows = self.items.count
            
            self.tableView.reloadData()
            
            if self.totalRows < 1 {
                self.showEmptyView()
            }
        }
    }
    
    func removeItems(indexRows: [Int]){
        
        for indexRow in indexRows {
            // make sure this index exists before we remove it
            if(indexRow < self.items.count){
                self.items.removeAtIndex(indexRow)
                self.totalRows = self.items.count
                
                self.tableView.reloadData()
                
                if self.totalRows < 1 {
                    self.showEmptyView()
                }
            }
        }
    }
    
    func refresh(refreshControl: UIRefreshControl) {
        // if not refreshing already
        if !self.isRefreshing {        
            self.isRefreshing = true

            self.clearData()
            
            self.pagedDataCall?(page: self.pageIndex, pageSize: self.pageSize)
        }
    }
    
    func resetPageIndex() {
        self.pageIndex = self.initialPageIndex
    }
    
    func setData<T where T: Hashable, T: TableViewCellModelType>(data: OrderedSet<T>) {

        // if first page load
        if self.pageIndex <= self.initialPageIndex {
            if data.count < 1 {
                self.clearData()
                
                // show empty options
                self.showEmptyView()
            }
            else {
                // reenable scrolling
                self.tableView.scrollEnabled        = self.scrollingEnabled
                self.tableView.alwaysBounceVertical = self.scrollingEnabled
            }
            
            for item in data {
                self.items.append(item)
            }
            
            // reload all cells (only first page at this point)
            self.tableView.reloadData()
        }
        else if data.count > 0 {
            // only append new rows without reloading entire tableview
            var newRows: [NSIndexPath] = []
            
            for item in data {
                self.items.append(item)
                newRows.append(NSIndexPath(forRow: self.items.count - 1, inSection: 0))
            }
            
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths(newRows, withRowAnimation: .None)
            self.tableView.endUpdates()
        }
        
        self.totalRows += data.count
    }
    
    func hideEmptyView() {
        // in case of previously set empty text
        self.errorViewController.removeErrorView()
    }
    
    func showEmptyView() {
        if let emptyText = self.emptyText {
            self.errorViewController.showErrorMessageView(self.view, text: emptyText, recoverButtonTitle: self.emptyButtonTitle, removeViewOnRecover: self.emptyRemoveViewOnRecover, recover: self.emptyRecover, recoverButtonFontSize: 22)
            
            self.tableView.scrollEnabled        = false
            self.tableView.alwaysBounceVertical = false
        }
    }
    
    func showLoadingMask() {
        if !self.isRefreshing {
            // if first page, show loading mask over the entire tableview
            if self.pageIndex <= self.initialPageIndex {
                self.loadingMaskViewController.queueLoadingMask(self.view, loadingViewAlpha: 1.0, showCompletion: nil)
                
                self.tableView.scrollEnabled        = false
                self.tableView.alwaysBounceVertical = false
            }
            // otherwise show loading mask in the footer
            else if let tableFooterView = self.tableView.tableFooterView {
                let view = UIView()
                view.frame = CGRectMake(tableFooterView.frame.origin.x, tableFooterView.frame.origin.y, tableFooterView.frame.width, 60)
                view.backgroundColor = self.tableView.backgroundColor
                
                // reassigning view handles table resigning (as opposed to just adjusting the frame)
                self.tableView.tableFooterView = view
                
                self.loadingMaskViewController.activityColor = self.activityIndicatorColor
                
                self.loadingMaskViewController.queueLoadingMask(view, loadingViewAlpha: 0, showCompletion: nil)
            }
        }
    }
}
