//
//  SignupQuestionAnswer.swift
//  Treem
//
//  Created by Matthew Walker on 10/15/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

struct SignupQuestionAnswer {
    var id          : String
    var answerText  : String
    
    init(json: JSON) {
        self.id         = json["a_id"].stringValue
        self.answerText = json["answer"].stringValue
    }
}