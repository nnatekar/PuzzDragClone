//
//  Orbs.swift
//  PuzzDragClone
//
//  Created by Neil Natekar on 7/3/18.
//  Copyright © 2018 None. All rights reserved.
//

import Foundation
import SpriteKit

// all different types of orbs
enum Type : String {
    case R = "ball-fire"
    case G = "ball-wood"
    case B = "ball-water"
    case L = "ball-light"
    case D = "ball-dark"
    case H = "ball-heart"
    case other = "garbage"
}

// Class that contains information about orbs
// Node = SKSpriteNode the orb is related to
// type = the type of the orb (ie. fire, water, wood)
// originalPos = the row and column of the board the orb is in
class Orb {
    var Node = SKSpriteNode()
    var type = Type.other
    var originalPos = [Int]() // [row, column]
    
    init(){}
    init(originalOrb: Orb){
        self.type = originalOrb.type
        self.originalPos = originalOrb.originalPos
    }
    init(originalOrb: Orb, node: SKSpriteNode){
        self.type = originalOrb.type
        self.originalPos = originalOrb.originalPos
        self.Node = node.copy() as! SKSpriteNode
    }
}

/**
 Function to create new orbs
 @param pos Position at which orb needs to be created
 @param tileBackground Board's tilemap
 @return currorb Newly created orb
 */
func orbCreate(tileBackground: SKTileMapNode, pos: CGPoint) -> Orb{
    let currorb = Orb()
    var text = SKTexture()
    let rand = arc4random_uniform(6)
    switch rand{ // choose color of orb based on random value
    case 0:
        currorb.type = Type.R
        text = SKTexture(imageNamed: currorb.type.rawValue)
    case 1:
        currorb.type = Type.G
        text = SKTexture(imageNamed: currorb.type.rawValue)
    case 2:
        currorb.type = Type.B
        text = SKTexture(imageNamed: currorb.type.rawValue)
    case 3:
        currorb.type = Type.L
        text = SKTexture(imageNamed: currorb.type.rawValue)
    case 4:
        currorb.type = Type.D
        text = SKTexture(imageNamed: currorb.type.rawValue)
    default:
        currorb.type = Type.H
        text = SKTexture(imageNamed: currorb.type.rawValue)
    }
    
    currorb.Node = SKSpriteNode(texture: text)
    currorb.Node.position = pos
    if(tileBackground.tileRowIndex(fromPosition: pos) < 5 && tileBackground.tileColumnIndex(fromPosition: pos) < 6) {
        currorb.originalPos = [tileBackground.tileRowIndex(fromPosition: pos), tileBackground.tileColumnIndex(fromPosition: pos)]
    }
    else{
        currorb.originalPos = [tileBackground.tileRowIndex(fromPosition: pos) - 5, tileBackground.tileColumnIndex(fromPosition: pos)]
    }
    currorb.Node.setScale(1.21)
    currorb.Node.physicsBody = SKPhysicsBody(circleOfRadius: 30)
    currorb.Node.physicsBody?.categoryBitMask = 1
    currorb.Node.physicsBody?.affectedByGravity = false
    return currorb
}


/**
 Function to find clusters of orbs around the given index that are same type as orb at given index
 @param orbs Array of orbs on the board
 @param index Index of orb to find clusters around
 @return cluster Set of indexes of orbs part of cluster
 Code taken from https://github.com/ethanlu/pazudora-solver
 */
func findCluster(orbs: [Orb], index: Int) -> Set<Int>{
    var cluster = Set<Int>()
    var search_stack = [index]
    while(search_stack.count > 0){
        let currInd = search_stack.popLast()!
        if(currInd >= 0 && currInd < 30 && !cluster.contains(currInd) && orbs[index].type == orbs[currInd].type && currInd % 6 != 0 && currInd % 6 != 5){
            cluster.update(with: currInd)
            search_stack.append(currInd-6)
            search_stack.append(currInd+6)
            search_stack.append(currInd-1)
            search_stack.append(currInd+1)
        }
        else if(currInd % 6 == 0 && currInd >= 0 && currInd < 30 && !cluster.contains(currInd) && orbs[index].type == orbs[currInd].type){ // don't add currInd - 1
            cluster.update(with: currInd)
            search_stack.append(currInd-6)
            search_stack.append(currInd+6)
            search_stack.append(currInd+1)
        }
        else if(currInd % 6 == 5 && currInd >= 0 && currInd < 30 && !cluster.contains(currInd) && orbs[index].type == orbs[currInd].type){ // don't add currInd + 1
            cluster.update(with: currInd)
            search_stack.append(currInd-6)
            search_stack.append(currInd+6)
            search_stack.append(currInd-1)
        }
    }
    
    return cluster
}


/**
 Function to determine which orbs in the board are matched
 @param orbs Array of orbs on the board
 @return all_matches Indices of all orbs which have been matched
 */
func findMatches(orbs: [Orb]) -> [Set<Int>] {
    var all_matches = [[Int]]()
    
    // find all vertical matches
    var vertical_matches = [[Int]]()
    var colsChecked = [Int]()
    var match = [Int]()
    var vertMatchesInd = 0
    for row in 0...2{
        for col in 0...5{
            // continue if column has already been fully checked
            if(vertical_matches.count > 0 && colsChecked.contains(col)) {
                continue
            }
            let index = rowMajorConversion(column: col, row: row)
            let orb1 = orbs[index].type
            let orb2 = orbs[index+6].type
            let orb3 = orbs[index+12].type
            
            // all orbs are same type
            if(orb1 == orb2 && orb2 == orb3) {
                match = [index, index+6, index+12]
                colsChecked.append(col)
                var checkMore = 5 - row
                var currMatchedOrbs = 3
                
                // continue checking the entire column so it can be skipped next iteration
                while(checkMore > 3){
                    let nextOrb = orbs[index + currMatchedOrbs * 6].type
                    
                    // next orb in column is part of current match
                    if(nextOrb == orb1){
                        match.append(index+currMatchedOrbs * 6)
                        currMatchedOrbs += 1
                    }
                    
                    checkMore -= 1
                }
                
                vertical_matches.append(match)
                vertMatchesInd += 1
            }
        }
    }
    
    // find horizontal matches
    var horizontal_matches = [[Int]]()
    match = [Int]()
    var rowsChecked = [Int]()
    
    for col in 0...3{
        for row in 0...4{
            
            if(horizontal_matches.count > 0 && colsChecked.contains(col)){
                continue
            }
            let index = rowMajorConversion(column: col, row: row)
            let orb1 = orbs[index].type
            let orb2 = orbs[index+1].type
            let orb3 = orbs[index+2].type
            
            if(orb1 == orb2 && orb2 == orb3){
                match = [index, index + 1, index + 2]
                rowsChecked.append(row)
                var checkMore = 6 - col
                var currMatchedOrbs = 3
                
                while(checkMore > 3){
                    let nextOrb = orbs[index + currMatchedOrbs].type
                    if(nextOrb == orb1){
                        match.append(index + currMatchedOrbs)
                        currMatchedOrbs += 1
                    }
                    
                    checkMore -= 1
                }
                
                horizontal_matches.append(match)
            }
        }
    }
    
    // find intersections between horizontal and vertical
    var i = 0
    var j = 0
    
    while(i < vertical_matches.count){
        while(j < horizontal_matches.count){
            let x = vertical_matches[i].filter(horizontal_matches[j].contains) // intersection between both
            
            // if there is an intersection, remove it from vertical & horizontal so it's not counted extra times
            if(x.count > 0){
                var singleMatch = vertical_matches[i] + horizontal_matches[j]
                vertical_matches.remove(at: i)
                horizontal_matches.remove(at: j)
                singleMatch.remove(at: singleMatch.index(of: x[0])!)
                all_matches.append(singleMatch)
            }
            j+=1
        }
        i+=1
    }
    all_matches += vertical_matches + horizontal_matches
    
    // now find all clusters around current matches and remove intersections between clusters and all_matches
    // code from here to end of function taken from https://github.com/ethanlu/pazudora-solver
    var matchLocations = Set<Int>()
    for i in 0..<all_matches.count{
        for j in 0..<all_matches[i].count{
            matchLocations.insert(all_matches[i][j])
        }
    }
    
    var clusters = [Set<Int>]()
    var memoized = Set<Int>()
    for ind in matchLocations{
        if(!memoized.contains(ind)){
            let cluster = findCluster(orbs: orbs, index: ind)
            clusters.append(cluster.intersection(matchLocations))
            memoized = memoized.union(cluster)
        }
    }
    
    return clusters
}
