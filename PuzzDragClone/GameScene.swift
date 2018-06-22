//
//  GameScene.swift
//  PuzzDragClone
//
//  Created by Neil Natekar on 6/12/18.
//  Copyright © 2018 None. All rights reserved.
//

import SpriteKit
import GameplayKit

enum Type : String {
    case R = "ball-fire"
    case G = "ball-wood"
    case B = "ball-water"
    case L = "ball-light"
    case D = "ball-dark"
    case H = "ball-heart"
    case other = "garbage"
}

class Orb {
    var Node = SKSpriteNode()
    var type = Type.other
}

class GameScene: SKScene {
    
    private var orb = SKSpriteNode()
    private var orbs = [[Orb]]()
    var prevPt : CGPoint!
    
    override func didMove(to view: SKView) {
        for index in 0...30{ // initialize all orbs in the board
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
        }
        let orbtexture = SKTexture(imageNamed: "ball-dark")
        orb = SKSpriteNode(texture: orbtexture)
        orb.position = CGPoint(x:-280, y:-40)
        orb.setScale(2)
        self.addChild(orb)
        print("x: \(orb.position.x), y: \(orb.position.y)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            if(nodes(at: location).contains(orb))
            {
                orb.run(SKAction.moveBy(x:location.x - orb.position.x, y:location.y - orb.position.y, duration: 0))
                print("x: \(orb.position.x), y: \(orb.position.y)")
            }
        }
        
    }
}
