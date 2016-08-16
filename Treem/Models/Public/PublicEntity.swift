//
//  PublicEntity.swift
//  Treem
//
//  Created by Daniel Sorrell on 1/28/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class PublicEntity{

    var public_link_id : Int            = 0
    var name           : String?        = nil
    var icon           : String?        = nil
//    var title          : String?        = nil
    var url            : String?        = nil
    var owner          : Bool           = false
    var iconImage      : UIImage?       = nil
    
    init(){}
    
    init(json: JSON) {
        self.public_link_id = json["id"].intValue
        self.icon           = json["icon"].string
        self.url            = json["url"].string
        self.owner          = (json["owner"].int == 1)
        
        // title = second half of name
        let title: String = json["title"].stringValue
        
        self.name = json["name"].stringValue + (title.isEmpty ? "" : " - " + title)
        
        if self.name!.isEmpty {
            self.name = nil
        }
    }
    
    // load the entities from the json
    static func loadPublicEntities(data: JSON) -> [PublicEntity]? {
        var entities: [PublicEntity]? = []
        
        for(_, object) in data {
            let entity = PublicEntity(json: object)
            
            if entity.public_link_id > 0 {
                entities?.append(entity)
            }
        }
        
        if(entities!.count < 1) { entities = nil }
        
        return entities
    }
    
    // return a JSON object for editing an entity (no position properties are changed)
    func entityUpdatePropertiesToJSON(json:JSON? = nil) -> JSON {
        var json:JSON = json ?? [:]
        
        // send public_link_id only when updating existing
        if self.public_link_id > 0 {
            json["id"].intValue = self.public_link_id
        }
        
        json["name"].string  = name
        json["icon"].string  = icon
        json["title"].string = name
        json["url"].string   = url
        
        return json
    }
}