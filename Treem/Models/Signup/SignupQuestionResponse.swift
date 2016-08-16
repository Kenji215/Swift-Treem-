//
//  SingupQuestionResponse.swift
//  Treem
//
//  Created by Matthew Walker on 10/13/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class SignupQuestionResponse {
    var id          : String?                   = nil
    var question    : String?                   = nil
    var answers     : [SignupQuestionAnswer]?   = nil
    
    init(json: JSON) {
        self.id         = json["id"].stringValue
        self.question   = json["question"].stringValue
        self.answers    = self.loadAnswers(json["answers"])
    }
    
    private func loadAnswers(data: JSON) -> [SignupQuestionAnswer] {
        var answers : [SignupQuestionAnswer] = []
        
        for (_, object) in data {
            answers.append(SignupQuestionAnswer(json: object))
        }
        
        return answers
    }
}

