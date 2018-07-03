//
//  GameScene.swift
//  PuzzDragClone
//
//  Created by Neil Natekar on 6/12/18.
//  Copyright © 2018 None. All rights reserved.
//  Assets taken from https://github.com/matthargett/padopt

import SpriteKit
import GameplayKit


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


// needed to convert 2D array to 1D
func rowMajorConversion(column: Int, row: Int) -> Int{
    return ((6 * row) + (column))
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var orb = SKSpriteNode() // using for testing
    private var orbs = [Orb]() // used to hold entire board of orbs
    private var tileBackground : SKTileMapNode! // contains background of tiles
    private var movingClone = Orb()
    private var movingOrb = Orb()
    
    func adjacentHorizontal(checkOrb: Int) -> Int{
        var retVal = Int()
        if(checkOrb % 6 == 0){ // nothing adjacent left
            retVal = -1
        }
        else{
            if(orbs[checkOrb].type == orbs[checkOrb-1].type){ // left value is same type
                retVal = checkOrb-1
            }
            else{ // left value is not same type
                retVal = -1
            }
        }
        
        return retVal
    }
    
    /**
        Function to create new orbs
        @param pos Position at which orb needs to be created
        @return currorb Newly created orb
     */
    func orbCreate(pos: CGPoint) -> Orb{
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
        Function to make orbs fall down and replace matched orbs
        @param ind Indices of orbs that need to be replaced
     */
    func skyfall(ind: [Int]) -> [SKAction]{
        var skyfallActions = [SKAction]()
        // orbs above garbage first fall down
        var skyfallOne = [Int]() // indices of all orbs that need to fall only one position down
        var skyfallTwo = [Int]() // indices that need to fall two down
        var skyfallThree = [Int]() // need to fall 3 down
        var skyfallFour = [Int]()
        for i in (6...29).reversed(){ // orbs 0-5 never need to skyfall
            if(orbs[i].type == Type.other){ // current is garbage, skip
                continue
            }
            var x = i - 6
            var count = 0
            while(x >= 0){ // count how many positions to skyfall
                if(orbs[x].type == Type.other){
                    count += 1
                }
                x -= 6
            }
            
            switch count{
            case 1:
                skyfallOne.append(i)
            case 2:
                skyfallTwo.append(i)
            case 3:
                skyfallThree.append(i)
            case 4:
                skyfallFour.append(i)
            default:
                break
            }
        }
        
        // move down all orbs to replace garbage
        for i in skyfallOne.reversed(){
            orbs[i-6] = orbs[i]
            orbs[i] = Orb(originalOrb: orbs[i-6], node: orbs[i-6].Node)
            orbs[i].type = Type.other
            orbs[i-6].originalPos = [orbs[i].originalPos[0] - 1, orbs[i].originalPos[1]] // go down one row
            skyfallActions.append(SKAction.run({
                self.orbs[i-6].Node.run(SKAction.sequence([SKAction.wait(forDuration: 1), SKAction.move(by: CGVector(dx: 0, dy: -125), duration: 0.5)]))
            })) // move it down
        }
        for i in skyfallTwo.reversed(){
            orbs[i-12] = orbs[i]
            orbs[i] = Orb(originalOrb: orbs[i-12], node: orbs[i-12].Node)
            orbs[i].type = Type.other
            orbs[i-12].originalPos = [orbs[i].originalPos[0] - 2, orbs[i].originalPos[1]] // go down one row
            skyfallActions.append(SKAction.run({
                self.orbs[i-12].Node.run(SKAction.sequence([SKAction.wait(forDuration: 1), SKAction.move(by: CGVector(dx: 0, dy: -125 * 2), duration: 0.5)]))
            })) // move it down
        }
        for i in skyfallThree.reversed(){
            orbs[i-18] = orbs[i]
            orbs[i] = Orb(originalOrb: orbs[i-18], node: orbs[i-18].Node)
            orbs[i].type = Type.other
            orbs[i-18].originalPos = [orbs[i].originalPos[0] - 3, orbs[i].originalPos[1]] // go down one row
            skyfallActions.append(SKAction.run({
                self.orbs[i-18].Node.run(SKAction.sequence([SKAction.wait(forDuration: 1), SKAction.move(by: CGVector(dx: 0, dy: -125 * 3), duration: 0.5)]))
            }))// move it down
        }
        for i in skyfallFour.reversed(){
            orbs[i-24] = orbs[i]
            orbs[i] = Orb(originalOrb: orbs[i-24], node: orbs[i-24].Node)
            orbs[i].type = Type.other
            orbs[i-24].originalPos = [orbs[i].originalPos[0] - 4, orbs[i].originalPos[1]] // go down one row
            skyfallActions.append(SKAction.run({
                self.orbs[i-24].Node.run(SKAction.sequence([SKAction.wait(forDuration: 1),SKAction.move(by: CGVector(dx: 0, dy: -125 * 4), duration: 0.5)]))
            }))
        }
        
        // next, fill in blank space at the top with new orbs
        for i in 0..<orbs.count{
            // need to skyfall a new orb
            if(orbs[i].type == Type.other){
                orbs[i].Node.removeFromParent()
                orbs[i] = orbCreate(pos: CGPoint(x: orbs[i].Node.position.x, y: orbs[i].Node.position.y + 125*5))
                skyfallActions.append(SKAction.run({
                    self.orbs[i].Node.run(SKAction.sequence([SKAction.wait(forDuration:1),SKAction.move(by: CGVector(dx:0, dy: -125*5), duration: 0.5)]))
                    self.addChild(self.orbs[i].Node)
                }))
            }
        }
        
        return skyfallActions
    }
    
    // code taken from https://github.com/ethanlu/pazudora-solver
    func findCluster(index: Int) -> Set<Int>{
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
        @return all_matches Indices of all orbs which have been matched
     */
    func findMatches() -> [Set<Int>] {
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
                let cluster = findCluster(index: ind)
                clusters.append(cluster.intersection(matchLocations))
                memoized = memoized.union(cluster)
            }
        }
        
        return clusters
    }
    
    
    /**
        Function which is called as soon as a contact begins
        Switches the two orbs that made contact
     */
    func didBegin(_ contact: SKPhysicsContact){
        // body A will be the moving orb
        // body b will be the orb to switch with
        let posA = movingClone.originalPos
        let indexA = rowMajorConversion(column: posA[1], row: posA[0])
        var bodyb = SKNode()
        
        // determine which contact body is body B
        if(contact.bodyA.node?.position == movingClone.Node.position) {
            bodyb = contact.bodyB.node!
        }
        else{
            bodyb = contact.bodyA.node!
        }
        
        // determine what row and column body B is in, determine its index on board
        let rowB = tileBackground.tileRowIndex(fromPosition: bodyb.position)
        let colB = tileBackground.tileColumnIndex(fromPosition: bodyb.position)
        let indexB = rowMajorConversion(column: colB, row: rowB)
        
        if((orbs[indexA].originalPos[1] == posA[1] && (orbs[indexA].originalPos[0]) < posA[0]-1 || orbs[indexA].originalPos[0] > posA[0]+1) ||
            (orbs[indexA].originalPos[0] == posA[0] && (orbs[indexA].originalPos[1]) < posA[1]-1 || orbs[indexA].originalPos[1] > posA[1]+1))
        {return}
        
        // change body B's original position, move it
        orbs[indexB].Node.run(SKAction.move(to: tileBackground.centerOfTile(atColumn: posA[1], row: posA[0]), duration: 0.25))
        orbs[indexA].originalPos = orbs[indexB].originalPos
        orbs[indexB].originalPos = posA
        movingOrb.Node.run(SKAction.move(to: tileBackground.centerOfTile(atColumn: colB, row: rowB), duration: 0))
        
        // switch orbs around in main array
        orbs[indexA] = orbs[indexB]
        orbs[indexB] = movingOrb
        
        // change body A's original position
        movingClone.originalPos = movingOrb.originalPos
    }
    
    
    /**
        Function that is called when touches end
        Detects matches and starts skyfalls
     */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        movingOrb.originalPos = movingClone.originalPos
        movingOrb.Node.run(SKAction.move(to: tileBackground.centerOfTile(atColumn: movingOrb.originalPos[1], row: movingOrb.originalPos[0]), duration: 0))
        movingOrb.Node.physicsBody?.categoryBitMask = 1
        movingOrb.Node.texture = SKTexture(imageNamed: movingOrb.type.rawValue)
        movingClone.Node.removeFromParent()
        
        var matchedSet = findMatches()
        var size = matchedSet.count
        var completeActions = [SKAction]()
        var numIter = 0.0
       // while(size > 0){
            print(size)
            var comboNum = 1
            var finishedIndices = [Int]()
            var labels = [SKLabelNode]()
            var lastIter = Double(matchedSet.count) / 0.2
            var saveInd = Int()
            for i in 0..<matchedSet.count{
                let label = SKLabelNode(fontNamed: "DIN Condensed")
                label.text = "Combo" + String(comboNum)
                label.fontSize = 31
                comboNum += 1
                for ind in matchedSet[i]{
                    var innerCount = 1
                    finishedIndices.append(ind)
                    let waitAction = SKAction.wait(forDuration: TimeInterval(numIter))
                    let fadeAction = SKAction.fadeOut(withDuration: 0.25)
                    let sequence = SKAction.sequence([waitAction, fadeAction])
                    if(numIter != lastIter && innerCount != matchedSet[i].count){
                        orbs[ind].Node.run(sequence, completion: {
                            self.orbs[ind].type = Type.other
                            self.orbs[ind].Node.removeFromParent()
                        })
                    }
                    else{
                        saveInd = ind
                    }
                     // know that the orb is finished
                    label.position = CGPoint(x: orbs[ind].Node.position.x, y: orbs[ind].Node.position.y)
                    innerCount += 1
                }
                self.addChild(label)
                labels.append(label)
                numIter += 0.375
            }
        
            // delay skyfall by 1 seconds so user can see the number of combos they made
            let waitAction = SKAction.wait(forDuration: numIter - 0.375)
            let fadeAction = SKAction.fadeOut(withDuration: 0.25)
            let sequence = SKAction.sequence([waitAction, fadeAction])
        orbs[saveInd].Node.run(sequence, completion:{
                self.orbs[saveInd].type = Type.other
                self.orbs[saveInd].Node.removeFromParent()
                let skyfallAction = self.skyfall(ind: finishedIndices)
            for action in skyfallAction{
                self.run(action)
            }
        })
            //let skyfallAction = self.skyfall(ind: finishedIndices)
           // for action in skyfallAction{
           // seq = SKAction.sequence([seq, action])
           // run(seq)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                for label in labels{
                    label.removeFromParent()
                }
            }
            matchedSet = self.findMatches()
            size = matchedSet.count
      //  }
        
            /*    comboFade.append(SKAction.run({
                    for j in 0..<matchedSet[i].count{
                        finishedIndices.append(matchedSet[i][j])
                        self.orbs[matchedSet[i][j]].Node.run(SKAction.fadeOut(withDuration: 0.5))
                        label.position = CGPoint(x: self.self.orbs[matchedSet[i][j]].Node.position.x, y: self.orbs[matchedSet[i][j]].Node.position.y)
                        self.orbs[matchedSet[i][j]].type = Type.other
                        self.orbs[matchedSet[i][j]].Node.removeFromParent()
                    }
                })) */
    }
    
    
    /**
        Function that intializes game and board
     */
    override func didMove(to view: SKView) {
        let tileBackground = childNode(withName: "BGTiles") as? SKTileMapNode
        self.tileBackground = tileBackground
        self.physicsWorld.contactDelegate = self
        
        for row in 0...4{ // initialize all orbs in the board
            for column in 0...5{
                orbs.append(orbCreate(pos: tileBackground!.centerOfTile(atColumn: column, row: row)))
                self.addChild(orbs[rowMajorConversion(column: column, row: row)].Node)
            }
        }
    }


    /**
        Function that is called when touches begin
        Creates an orb clone used to move around other orbs
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let location = touch!.location(in: self)
        
        let row = tileBackground.tileRowIndex(fromPosition: location)
        let col = tileBackground.tileColumnIndex(fromPosition: location)
        
        if(!(row < 5 && col < 6)){
            return
        }
        // set up orb to be moved, temporarily change categorybitmask so not affected by contact
        movingOrb = orbs[rowMajorConversion(column: col, row: row)]
        movingOrb.Node.physicsBody?.categoryBitMask = 0
        movingOrb.Node.physicsBody?.collisionBitMask = 0
        
        // set up orb clone which will be moved
        movingClone = Orb(originalOrb: movingOrb)
        movingClone.Node = SKSpriteNode(texture: SKTexture(imageNamed: movingClone.type.rawValue))
        movingClone.Node.position = movingOrb.Node.position
        movingClone.Node.setScale(1.21)
        movingClone.Node.physicsBody = SKPhysicsBody(circleOfRadius: 30)
        movingClone.Node.physicsBody?.categoryBitMask = 2
        movingClone.Node.physicsBody?.contactTestBitMask = 1
        movingClone.Node.physicsBody?.affectedByGravity = false
        self.addChild(movingClone.Node)
        
        movingOrb.Node.texture = SKTexture(imageNamed: movingOrb.type.rawValue + "-clone")
        movingOrb.Node.removeFromParent()
        self.addChild(orbs[rowMajorConversion(column: col, row: row)].Node)
    }
    
    
    /**
        Function that is called whenever user moves orb
        Moves orb along with user's finger
     */
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // only use first touch every time it's moved so it runs faster
        let touch = touches.first
        let location = touch!.location(in:self)
        
        // set boundary for orbs
        if(location.x > -self.frame.width / 2 && location.x < self.frame.width / 2){
            movingClone.Node.run(SKAction.move(to: CGPoint(x: location.x, y: location.y), duration: 0))
        }
        
        // count it as collision, need to switch orbs
        if(location.y > -self.frame.height / 2 + 600 && tileBackground.tileColumnIndex(fromPosition: location) != tileBackground.tileColumnIndex(fromPosition: movingOrb.Node.position)){
            
            // find indices of both orbs in main array
            let indexA = rowMajorConversion(column: movingClone.originalPos[1], row: movingClone.originalPos[0])
            let rowB = 4
            let colB = tileBackground.tileColumnIndex(fromPosition: location)
            let indexB = rowMajorConversion(column: colB, row: rowB)
            
            // animate orb switches
            orbs[indexB].Node.run(SKAction.move(to: tileBackground.centerOfTile(atColumn: movingClone.originalPos[1], row: movingClone.originalPos[0]), duration: 0.25))
            orbs[indexA].originalPos = orbs[indexB].originalPos
            orbs[indexB].originalPos = movingClone.originalPos
            movingOrb.Node.run(SKAction.move(to: tileBackground.centerOfTile(atColumn: colB, row: rowB), duration: 0))
            
            // switch orbs in array
            orbs[indexA] = orbs[indexB]
            orbs[indexB] = movingOrb
            
            movingClone.originalPos = movingOrb.originalPos
        }
    }
}
