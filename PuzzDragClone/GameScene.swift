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
    var originalPos = CGPoint()
}

func rowMajorConversion(column: Int, row: Int) -> Int{ // needed to convert 2D array to 1D
    return ((6 * row) + (column))
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    private var orb = SKSpriteNode() // using for testing
    private var orbs = [Orb]() // used to hold entire board of orbs
    private var tileBackground : SKTileMapNode! // contains background of tiles
    private var movingOrb = Orb()
    
    func didBegin(_ contact: SKPhysicsContact){
        print("Starting collision")
        let posA = contact.bodyA.node?.position
        contact.bodyA.node?.run(SKAction.move(to: (contact.bodyB.node?.position)!, duration: 0))
        contact.bodyB.node?.run(SKAction.move(to: posA!, duration:0))
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
                currorb.originalPos = currorb.Node.position
                currorb.Node.setScale(1.21)
                currorb.Node.physicsBody = SKPhysicsBody(circleOfRadius: 60.5)
                currorb.Node.physicsBody?.categoryBitMask = 0x1 << 1
                currorb.Node.physicsBody?.contactTestBitMask = 0x1 << 1
                currorb.Node.physicsBody?.isDynamic = false
                currorb.Node.physicsBody?.usesPreciseCollisionDetection = true
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
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            movingOrb.Node.run(SKAction.moveBy(x:location.x - movingOrb.Node.position.x, y:location.y - movingOrb.Node.position.y, duration: 0))
            print("Moving: \(movingOrb.Node.position.x), \(movingOrb.Node.position.y), static: \(orbs[0].Node.position.x), \(orbs[0].Node.position.y)")
        }
        
    }
}
