//
//  Branch.swift
//  Treem
//
//  Created by Matthew Walker on 7/14/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

enum BranchPosition: Int {
    case Center      = 0
    case Left        = 1
    case TopLeft     = 2
    case TopRight    = 3
    case Right       = 4
    case BottomRight = 5
    case BottomLeft  = 6
    case None        = -1
}

class Branch: Equatable  {
    
    enum ExploreType: Int {
        case News               = 0
        case Sports             = 1
        case Business           = 2
        case Entertainment      = 3
        case Media              = 4
        case Tech               = 5
        case Science            = 6
    }
    
    var id              : Int            = 0
    var position        : BranchPosition = BranchPosition.Center
    var color           : UIColor?       = nil
    var title           : String?        = nil
    var icon            : String?        = nil
    var url             : String?        = nil
    var exploreType     : ExploreType?   = nil
    var public_link_id  : Int            = 0
    var public_owner    : Bool           = false
    var parent          : Branch?        = nil
    var children        : [Branch]?      = nil
    
    var iconImage: UIImage? = nil // cache icon image
    
    init() {}
    
    init(json: JSON, parent: Branch?) {
        self.id             = json["id"].intValue
        self.position       = BranchPosition(rawValue: json["position"].intValue) ?? BranchPosition.None
        self.color          = UIColor(hex: json["color"].stringValue)
        self.title          = json["name"].string
        self.icon           = json["icon"].string
        self.url            = json["url"].string
        self.public_link_id = json["public_link_id"].intValue
        self.public_owner   = (json["public_owner"].intValue == 1)
        
        if let exTypeInt = json["ex_type"].int {
            self.exploreType    = ExploreType(rawValue: exTypeInt ?? ExploreType.News.rawValue)
        }
        
        self.parent         = parent
        self.children       = self.loadBranches(json["children"], parent: self)
    }

    // return a JSON object for editing a branch (no position properties are changed)
    func branchUpdatePropertiesToJSON(json:JSON? = nil) -> JSON {
        var json:JSON = json ?? [:]
        
        // send branch_id only when updating existing
        if self.id > 0 {
            json["id"].intValue      = self.id
        }
        
        // if public link id was given, use that instead of name (public tree)
        if self.public_link_id > 0 {
            json["public_link_id"].intValue = self.public_link_id
        }
        else{
            json["name"].string = self.title
        }
        
        if let publicURL = self.url {
            json["url"].string = publicURL
        }
        
        if let color = self.color {
            json["color"].stringValue   = color.toHexString(false)
        }
        
        return json
    }
    
    // returns a JSON object for a new branch
    func branchNewPropertiesToJSON(treeID: Int) -> JSON {
        var json:JSON = self.branchUpdatePropertiesToJSON([:])
        
        json["position"].intValue    = self.position.rawValue
        
        if let parent = self.parent {
            if parent.id > 0 {
                json["parent_id"].intValue = parent.id
            }
        }
            
        return json
    }
    
    // returns a JSON object for a branch move
    func branchMovePropertiesToJSON(treeID: Int, newParentID: Int, newPosition: BranchPosition) -> JSON {
        var json: JSON = [:]
        
        json["id"].intValue         = self.id
        json["position"].intValue   = newPosition.rawValue
        json["parent_id"].intValue  = newParentID
        
        return json
    }

    func branchPlacementToJSON() -> JSON {
        var json: JSON = [:]

        json["position"].intValue   = self.position.rawValue
        json["parent_id"].intValue  = self.parent!.id

        return json
    }
    
    func getPublicEntityFromBranchProperties() -> PublicEntity? {
        // if entity is tied to branch there is a url
        if let url = self.url {
            let entity = PublicEntity()
            
            entity.public_link_id   = self.public_link_id
            entity.icon             = self.icon
            entity.iconImage        = self.iconImage
            entity.url              = url
            entity.owner            = self.public_owner
            entity.name             = self.title
            
            return entity
        }
        
        return nil
    }
    
    func updateBranchFromEntityProperties(entity: PublicEntity) {
        self.public_link_id = entity.public_link_id
        self.icon           = entity.icon
        self.iconImage      = entity.iconImage
        self.title          = entity.name
        self.url            = entity.url
        self.public_owner   = entity.owner
    }
    
    // recursively load sub branch network
    func loadBranches(data: JSON, parent: Branch?) -> [Branch]? {
        var branches: [Branch]? = []
        
        for (_, object) in data {
            let childBranch = Branch(json:object, parent: parent)
            
            if(childBranch.position != BranchPosition.None && childBranch.id > 0) {
                branches!.append(childBranch)
            }
            
            self.loadBranches(object["child_branches"], parent: self)
        }
        
        if branches!.count < 1 {
            branches = nil
        }
        
        return branches
    }
    

}

// positions are equal if the id available for each and they match
func ==(lhs: Branch, rhs: Branch) -> Bool {
    return (lhs.id > 0) && (lhs.id == rhs.id)
}
