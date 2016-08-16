//
//  EntityResultsTableViewController
//  Treem
//
//  Created by Matthew Walker on 4/4/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

class EntitySearchResultsTableViewController: PagedTableViewController {
    private var entities : [PublicEntity] = []
    
    private var currentSearchText   : String? = nil
    
    private let loadingMaskViewController = LoadingMaskViewController.getStoryboardInstance()
    
    var delegate: EntitySearchDelegate? = nil
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.useRefreshControl = true
    }
    
    // MARK: TableView Controller Methods
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.entities.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let entity = self.entities.indices.contains(indexPath.row) ? self.entities[indexPath.row] : PublicEntity()
        
        // check which cell prototype to use
        
        // Pre-existing
        if entity.public_link_id > 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("PublicTreeDefaultLinkCell") as! PublicTreeSearchTableViewCell
            
            // remove current image (recycling cell)
            cell.searchIcon.image   = UIImage(named: "Explore")
            
            if(self.entities.indices.contains(indexPath.row)) {
                let entity = self.entities[indexPath.row]
                
                // load the icon
                ImageLoader.sharedInstance.loadPublicImage(
                    entity.icon,
                    success: {
                        image in
                        
                        cell.searchIcon.image = image
                        
                        entity.iconImage = image
                    },
                    failure: {

                        #if DEBUG
                            print("Failed to load image: \(entity.icon)")
                        #endif
                    }
                )
                
                cell.searchName.text    = entity.name
                cell.searchUrl.text     = entity.url
            }
            
            return cell
        }
        // Url only 
        else if let url = entity.url {
            let cell = tableView.dequeueReusableCellWithIdentifier("PublicTreeCustomLinkCell") as! PublicTreeLinkTableViewCell
            
            cell.urlLabel.text = url
            
            return cell
        }
        // Create Branch
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("PublicTreeCreateBranchCell")!
            
            // static cell, just return
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(self.entities.indices.contains(indexPath.row)){
            let entity = self.entities[indexPath.row]
            
            self.delegate?.selectedEntity(entity)
        }
    }
    
    func setEntities(entities: [PublicEntity], emptyText: String? = nil) {
        self.emptyText          = emptyText

        // If this is a new search, reset the stored data.
        if self.pageIndex <= self.initialPageIndex {
            self.entities = []
            self.clearData()
        }
        
        self.entities.appendContentsOf(entities)
        
        self.tableView.reloadData()
    }
}
