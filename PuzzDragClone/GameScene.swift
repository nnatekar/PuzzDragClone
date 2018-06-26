//
//  GameScene.swift
//  PuzzDragClone
//
//  Created by Neil Natekar on 6/12/18.
//  Copyright © 2018 None. All rights reserved.
//

import SpriteKit
import GameplayKit

enum Type : String { // all different types of orbs
    case R = "ball-fire"
    case G = "ball-wood"
    case B = "ball-water"
    case L = "ball-light"
    case D = "ball-dark"
    case H = "ball-heart"
    case other = "garbage"
}

class Orb { // contains properties of each orb
    var Node = SKSpriteNode()
    var type = Type.other
    var originalPos = [Int]()
}

class clonedOrb: Orb {
    var originalOrbIndex = Int()
    
    override init(){super.init()}
    init(originalOrb: Orb){
        super.init()
        self.type = originalOrb.type
        self.originalPos = originalOrb.originalPos
    }
}

func rowMajorConversion(column: Int, row: Int) -> Int{ // needed to convert 2D array to 1D
    return ((6 * row) + (column))
}



class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var orb = SKSpriteNode() // using for testing
    private var orbs = [Orb]() // used to hold entire board of orbs
    private var tileBackground : SKTileMapNode! // contains background of tiles
    private var movingClone = clonedOrb()
    private var movingOrb = Orb()
    
    func findMatches() -> [[Int]] {
        var all_matches = [[Int]]()
        
        // find all vertical matches
        var vertical_matches = [[Int]]()
        var match = [Int]()
        var colsChecked = [Int]()
        
        for row in 0...2{ // ORBS GO BOTTOM -> TOP NOT TOP -> BOTTOM
            for col in 0...5{
                if(vertical_matches.count > 0 && colsChecked.contains(col)) { // continue if column has already been fully checked
                    print("Continued to next!")
                    continue
                }
                let index = rowMajorConversion(column: col, row: row)
                let orb1 = orbs[index].type
                let orb2 = orbs[index+6].type
                let orb3 = orbs[index+12].type
                
                if(orb1 == orb2 && orb2 == orb3) { // all orbs are same type
                    match = [index, index+6, index+12]
                    colsChecked.append(col)
                    var checkMore = 5 - row
                    var currMatchedOrbs = 3
                    
                    while(checkMore > 3){ // continue checking the entire column so it can be skipped next iteration
                        let nextOrb = orbs[index + currMatchedOrbs * 6].type
                        if(nextOrb == orb1){
                            match.append(index+currMatchedOrbs * 6)
                            currMatchedOrbs += 1
                        }
                        checkMore -= 1
                    }
                    
                    vertical_matches.append(match)
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
                
                print("\(orbs[index].Node)\n\(orbs[index+1].Node)\n\(orbs[index+2].Node)\n\n")
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
        
        all_matches += vertical_matches // testing
        all_matches += horizontal_matches
        return all_matches
    }
    
    func didBegin(_ contact: SKPhysicsContact){
        // body A will be the moving orb
        // body b will be the orb to switch with
        let posA = movingClone.originalPos
        let indexA = rowMajorConversion(column: posA[1], row: posA[0])
        var bodyb = SKNode()
        
        // determine which contact body is body B
        if(contact.bodyA.node?.position == movingClone.Node.position) {
            bodyb = contact.bodyA.node!
        }
        else{
            bodyb = contact.bodyB.node!
        }
        
        // determine what row and column body B is in, determine it's index on board
        let rowB = tileBackground.tileRowIndex(fromPosition: bodyb.position)
        let colB = tileBackground.tileColumnIndex(fromPosition: bodyb.position)
        let indexB = rowMajorConversion(column: colB, row: rowB)
        
        // change body B's original position, move it
        movingOrb.Node.run(SKAction.move(to: tileBackground.centerOfTile(atColumn: colB, row: rowB), duration: 0))
        orbs[indexB].originalPos = posA
        orbs[indexB].Node.run(SKAction.move(to: tileBackground.centerOfTile(atColumn: posA[1], row: posA[0]), duration: 0.25))
        
        orbs[indexA] = orbs[indexB]
        orbs[indexB] = movingOrb
        
        // change body A's original position
        movingClone.originalPos = [rowB, colB]
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        movingOrb.originalPos = movingClone.originalPos
        movingOrb.Node.run(SKAction.move(to: tileBackground.centerOfTile(atColumn: movingOrb.originalPos[1], row: movingOrb.originalPos[0]), duration: 0))
        movingOrb.Node.physicsBody?.categoryBitMask = 1
        movingOrb.Node.texture = SKTexture(imageNamed: movingOrb.type.rawValue)
        movingClone.Node.removeFromParent()
        movingOrb.Node.removeFromParent()
        self.addChild(movingOrb.Node)
     //   movingOrb.Node.run(SKAction.fadeOut(withDuration: 0.5))
        
        let matchedSet = findMatches()
        var comboNum = 1
        for i in 0..<matchedSet.count{
            let label = SKLabelNode(fontNamed: "DIN Condensed")
            label.text = "Combo" + String(comboNum)
            label.fontSize = 31
            comboNum += 1
            for j in 0..<matchedSet[i].count{
                self.orbs[matchedSet[i][j]].Node.run(SKAction.fadeOut(withDuration: 0.5))
                label.position = CGPoint(x: orbs[matchedSet[i][j]].Node.position.x, y: orbs[matchedSet[i][j]].Node.position.y)
                
            }
            self.addChild(label)
        }
    }
    
    override func didMove(to view: SKView) {
        let tileBackground = childNode(withName: "BGTiles") as? SKTileMapNode
        self.tileBackground = tileBackground
        self.physicsWorld.contactDelegate = self
        
        for row in 0...4{ // initialize all orbs in the board
            for column in 0...5{
                var text = SKTexture() // contains the orb texture
                let currorb = Orb() // current orb to be initialized
                
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
                currorb.Node.position = tileBackground!.centerOfTile(atColumn: column, row: row)
                currorb.originalPos = [row, column]
                currorb.Node.setScale(1.21)
                currorb.Node.physicsBody = SKPhysicsBody(circleOfRadius: 25)
                currorb.Node.physicsBody?.categoryBitMask = 1
                currorb.Node.physicsBody?.affectedByGravity = false
                orbs.append(currorb)
                self.addChild(orbs[rowMajorConversion(column: column, row: row)].Node)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let location = touch!.location(in: self)
        
        let row = tileBackground.tileRowIndex(fromPosition: location)
        let col = tileBackground.tileColumnIndex(fromPosition: location)
        
        // set up orb to be moved, temporarily change categorybitmask so not affected by contact
        movingOrb = orbs[rowMajorConversion(column: col, row: row)]
        movingOrb.Node.physicsBody?.categoryBitMask = 0
        movingOrb.Node.physicsBody?.collisionBitMask = 0
        
        // set up orb clone which will be moved
        movingClone = clonedOrb(originalOrb: movingOrb)
        movingClone.originalOrbIndex = rowMajorConversion(column: col, row: row)
        movingClone.Node = SKSpriteNode(texture: SKTexture(imageNamed: movingClone.type.rawValue))
        movingClone.Node.position = movingOrb.Node.position
        movingClone.Node.setScale(1.21)
        movingClone.Node.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        movingClone.Node.physicsBody?.categoryBitMask = 2
        movingClone.Node.physicsBody?.contactTestBitMask = 1
        movingClone.Node.physicsBody?.affectedByGravity = false
        self.addChild(movingClone.Node)
        
        movingOrb.Node.texture = SKTexture(imageNamed: movingOrb.type.rawValue + "-clone")
        movingOrb.Node.removeFromParent()
        self.addChild(orbs[rowMajorConversion(column: col, row: row)].Node)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // only use first touch every time it's moved so it runs faster
        let touch = touches.first
        let location = touch!.location(in:self)
        
        // set boundary for orbs
        if(location.y < -self.frame.height / 2 + 600 && location.y > -self.frame.height / 2 && location.x > -self.frame.width / 2 && location.x < self.frame.width / 2){
            movingClone.Node.run(SKAction.moveBy(x:location.x - movingClone.Node.position.x, y:location.y - movingClone.Node.position.y, duration: 0))
        }
    }
}
