//
//  EntitySearchViewController.swift
//  Treem
//
//  Created by Matthew Walker on 4/4/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

class EntitySearchViewController : UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var resultsContainerView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var headerView: UIView!
    
    @IBAction func cancelButtonTouchUpInside(sender: AnyObject) {
        
        self.dismissKeyboard()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private let loadingMaskViewController       = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController             = ErrorViewController.getStoryboardInstance()
    
    private var resultsTableVC      : EntitySearchResultsTableViewController!
    private var tapGestureRecognizer: UITapGestureRecognizer? = nil
    
    var searchTimer             : NSTimer?
    var searchTimerDelay        : NSTimeInterval = 0.5
    var currentSearchText       : String? = nil
    
    var delegate: EntitySearchDelegate? = nil
    
    static func getStoryboardInstance() -> EntitySearchViewController {
        return UIStoryboard(name: "EntitySearch", bundle: nil).instantiateViewControllerWithIdentifier("EntitySearch") as! EntitySearchViewController
    }
    
    // MARK: View Controller Methods
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbedEntitiesSearchResults" {
            self.resultsTableVC             = (segue.destinationViewController as! EntitySearchResultsTableViewController)
            self.resultsTableVC.delegate    = self.delegate
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.dismissKeyboard()
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.searchBar.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppStyles.sharedInstance.setSubHeaderBarStyles(self.headerView)
        
        self.cancelButton.tintColor = AppStyles.sharedInstance.whiteColor
        
        self.searchBar.delegate = self
        
        self.getEntities()
    }
    
    // MARK: Search Bar Methods
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        var search = searchText // make copy
        
        // cancel previous timer
        if let timer = self.searchTimer {
            timer.invalidate()
        }
        
        // if text is url make lower case
        if !search.parseForUrl().isEmpty {
            search = search.lowercaseString
            
            self.searchBar.text = search
        }
        
        self.currentSearchText = search
        
        // reset paging
        self.resultsTableVC.resetPageIndex()
        
        // if search is empty add no delay, otherwise add delay for when typing
        self.searchTimer = NSTimer.scheduledTimerWithTimeInterval(
            search.isEmpty ? 0 : self.searchTimerDelay,
            target: self,
            selector: #selector(EntitySearchViewController.getEntities),
            userInfo: nil,
            repeats: false
        )
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        //Looks for taps on table view
        if self.tapGestureRecognizer == nil {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(EntitySearchViewController.dismissKeyboard))
            self.tapGestureRecognizer?.cancelsTouchesInView = false
            self.resultsTableVC.view.addGestureRecognizer(self.tapGestureRecognizer!)
        }
    }
    
    // MARK: Data retrieval methods
    
    func getEntities() {
        // remove prior error view (if added)
        self.errorViewController.removeErrorView()
        
        self.resultsTableVC.pagedDataCall = self.searchPublicTree
        
        self.searchPublicTree(self.resultsTableVC.pageIndex, pageSize: self.resultsTableVC.pageSize)
    }
    
    private func searchPublicTree(page: Int, pageSize: Int) {
        
        self.resultsTableVC.showLoadingMask()
        
        TreemPublicService.sharedInstance.getEntities(
            page,
            pageSize: pageSize,
            search: self.currentSearchText,
            success: {
                (data:JSON) in

                if let results = PublicEntity.loadPublicEntities(data) {
                    self.resultsTableVC.setEntities(self.addPrependingOptionsFromSearch(results))
                }
                else {
                    self.resultsTableVC.setEntities(self.addPrependingOptionsFromSearch([]))
                }
                
                self.resultsTableVC.cancelLoadingMask()
            },
            failure: {
                (error, wasHandled) -> Void in
                
                if(!wasHandled) {
                    // cancel loading mask and return to view with alert
                    self.resultsTableVC.cancelLoadingMask()
                    
                    CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                }
        })
    }
    
    private func addPrependingOptionsFromSearch(entities: [PublicEntity]) -> [PublicEntity] {
        var returnEntities = entities
        
        // if on first page
        if self.resultsTableVC.pageIndex <= self.resultsTableVC.initialPageIndex {
            var addEmptyEntity = true
            
            // check if text entered (show add branch option)
            if let text = self.currentSearchText {
                let url = text.trim().parseForUrl()
                
                if !url.isEmpty {
                    // text is valid url, prepend url only option
                    let entity = PublicEntity()
                    
                    entity.url      = url
                    entity.owner    = true
                    
                    returnEntities.insert(entity, atIndex: 0)
                    
                    addEmptyEntity = false
                }
            }
                
            if addEmptyEntity {
                // text is regular wording, add branch creation option (empty entity)
                returnEntities.insert(PublicEntity(), atIndex: 0)
            }
        }
        
        return returnEntities
    }
    
    // MARK: Helper methods
    
    // clear open keyboards on tap
    func dismissKeyboard() {
        self.view.endEditing(true)
        self.searchBar.resignFirstResponder()
        
        if self.tapGestureRecognizer != nil {
            self.resultsTableVC.view.removeGestureRecognizer(self.tapGestureRecognizer!)
            self.tapGestureRecognizer = nil
        }
    }
}
