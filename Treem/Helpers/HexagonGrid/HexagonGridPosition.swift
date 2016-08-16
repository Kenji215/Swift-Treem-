//
//  HexagonGridPosition.swift
//  Treem
//
//  Specifies a x,y grid location in a hexagon grid. For example a button at (0, 0) could the button at the
//  center of the grid and (0, 1) could be the position of the hexagon to the right of it.
//
//
//  Created by Matthew Walker on 7/31/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//


struct HexagonGridPosition : Hashable {
    var x: Int
    var y: Int
    
    var hashValue: Int {
        return "\(x),\(y)".hashValue
    }
    
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

// positions are equal if both x and y value match
func ==(lhs: HexagonGridPosition, rhs: HexagonGridPosition) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

func ==(lhs: HexagonGridPosition, rhs: (Int, Int)) -> Bool {
    return lhs.x == rhs.0 && lhs.y == rhs.1
}

func +(lhs: HexagonGridPosition, rhs: (Int, Int)) -> HexagonGridPosition {
    var position = lhs
    
    position.x += rhs.0
    position.y += rhs.1
    
    return position
}