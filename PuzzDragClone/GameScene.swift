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

func rowMajorConversion(column: Int, row: Int) -> Int{ // needed to convert 2D array to 1D
    return ((6 * row) + (column))
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    private var orb = SKSpriteNode() // using for testing
    private var orbs = [Orb]() // used to hold entire board of orbs
    private var tileBackground : SKTileMapNode! // contains background of tiles
    private var movingOrb = Orb()
    private var indToOrb = [Int : Int]() // dictionary containing translation of index to orb
    
    func didBegin(_ contact: SKPhysicsContact){
        // body A will be the moving orb
        // body b will be the orb to switch with
        let posA = movingOrb.originalPos
        let rowMajA = rowMajorConversion(column: posA[1], row: posA[0])
        var bodyb = SKNode()
        
        // determine which contact body is body B
        if(contact.bodyA.node?.position == movingOrb.Node.position) {
            bodyb = contact.bodyA.node!
        }
        else{
            bodyb = contact.bodyB.node!
        }
        
        // determine what row and column body B is in, determine it's index on board
        let rowB = tileBackground.tileRowIndex(fromPosition: bodyb.position)
        let colB = tileBackground.tileColumnIndex(fromPosition: bodyb.position)
        let indexB = indToOrb[rowMajorConversion(column: colB, row: rowB)]
        let rowMajB = rowMajorConversion(column: colB, row: rowB)
        
        // change body B's original position, move it, and update dictionary value at the orb
        orbs[indexB!].originalPos = [posA[0], posA[1]]
        orbs[indexB!].Node.run(SKAction.move(to: tileBackground.centerOfTile(atColumn: posA[1], row: posA[0]), duration: 0.5))
        indToOrb[rowMajB] = rowMajA
        
        // change body A's original position and update its dictionary value
        movingOrb.originalPos = [rowB, colB]
        indToOrb[rowMajA] = rowMajB
        
    }
    
    override func didMove(to view: SKView) {
        let tileBackground = childNode(withName: "BGTiles") as? SKTileMapNode
        self.tileBackground = tileBackground
        self.physicsWorld.contactDelegate = self
        
        for row in 0...4{ // initialize all orbs in the board
            for column in 0...5{
                var text = SKTexture() // contains the orb texture
                let currorb = Orb() // current orb to be initialized
                indToOrb[rowMajorConversion(column: column, row: row)] = rowMajorConversion(column: column, row: row)
                
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
                currorb.Node.physicsBody = SKPhysicsBody(circleOfRadius: 10)
                currorb.Node.physicsBody?.categoryBitMask = 1
                currorb.Node.physicsBody?.contactTestBitMask = 1
                currorb.Node.physicsBody?.usesPreciseCollisionDetection = true
                currorb.Node.physicsBody?.affectedByGravity = false
                orbs.append(currorb)
                self.addChild(orbs[rowMajorConversion(column: column, row: row)].Node)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let location = touch!.location(in: self)
        for index in 0..<30{
            if(nodes(at:location).contains(orbs[index].Node)){
                movingOrb = orbs[index]
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // only use first touch every time it's moved so it runs faster
        let touch = touches.first
        let location = touch!.location(in:self)
        
        // set boundary for orbs
        if(location.y < -self.frame.height / 2 + 600 && location.y > -self.frame.height / 2 && location.x > -self.frame.width / 2 && location.x < self.frame.width / 2){
            movingOrb.Node.run(SKAction.moveBy(x:location.x - movingOrb.Node.position.x, y:location.y - movingOrb.Node.position.y, duration: 0))
        }
    }
}
