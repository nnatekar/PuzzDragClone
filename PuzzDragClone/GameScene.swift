//
//  GameScene.swift
//  PuzzDragClone
//
//  Created by Neil Natekar on 6/12/18.
//  Copyright © 2018 None. All rights reserved.
//  Assets taken from https://github.com/matthargett/padopt

import GameplayKit

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
        
        // go down each column and count how many positions each orb skyfalls, orbs 0-5 never need to skyfall
        for i in (6...29).reversed(){
            // current is garbage, skip
            if(orbs[i].type == Type.other){
                continue
            }
            
            var x = i - 6
            var count = 0
            // count how many positions to skyfall
            while(x >= 0){
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
                orbs[i] = orbCreate(tileBackground: tileBackground, pos: CGPoint(x: orbs[i].Node.position.x, y: orbs[i].Node.position.y + 125*5))
                skyfallActions.append(SKAction.run({
                    self.orbs[i].Node.run(SKAction.sequence([SKAction.wait(forDuration:1),SKAction.move(by: CGVector(dx:0, dy: -125*5), duration: 0.5)]))
                    self.addChild(self.orbs[i].Node)
                }))
            }
        }
        
        return skyfallActions
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
        // Move movingOrb to its final location and remove clone
        movingOrb.originalPos = movingClone.originalPos
        movingOrb.Node.run(SKAction.move(to: tileBackground.centerOfTile(atColumn: movingOrb.originalPos[1], row: movingOrb.originalPos[0]), duration: 0))
        movingOrb.Node.physicsBody?.categoryBitMask = 1
        movingOrb.Node.texture = SKTexture(imageNamed: movingOrb.type.rawValue)
        movingClone.Node.removeFromParent()
        
        // find matches and skyfall new orbs
        var matchedSet = findMatches(orbs: orbs)
        var numIter = 0.0
        var comboNum = 1
        var finishedIndices = [Int]()
        var labels = [SKLabelNode]()
        let lastIter = Double(matchedSet.count) * 0.375 - 0.375
        var saveInd = Int()
        
        // go through all matches and create a combo label
        for i in 0..<matchedSet.count{
            let label = SKLabelNode(fontNamed: "DIN Condensed")
            label.text = "Combo" + String(comboNum)
            label.fontSize = 31
            comboNum += 1
            var innerCount = 1
            
            // go through all orbs in a combo and get rid of them
            for ind in matchedSet[i]{
                finishedIndices.append(ind)
                let waitAction = SKAction.wait(forDuration: TimeInterval(numIter))
                let fadeAction = SKAction.fadeOut(withDuration: 0.25)
                let sequence = SKAction.sequence([waitAction, fadeAction])
                
                // get rid of orb unless it's the last orb to get rid of
                if(numIter == lastIter && innerCount == matchedSet[i].count){
                    saveInd = ind // save last orb's index
                }
                else{
                    orbs[ind].Node.run(sequence, completion: {
                        self.orbs[ind].type = Type.other
                        self.orbs[ind].Node.removeFromParent()
                    })
                }
                
                label.position = CGPoint(x: orbs[ind].Node.position.x, y: orbs[ind].Node.position.y)
                innerCount += 1
            }
            
            // add the combo label
            self.addChild(label)
            labels.append(label)
            numIter += 0.375
        }
    
        // get rid of last orb, then skyfall
        let waitAction = SKAction.wait(forDuration: numIter - 0.375+0.05)
        let fadeAction = SKAction.fadeOut(withDuration: 0.25)
        let remove = SKAction.run({
            self.orbs[saveInd].type = Type.other
            self.orbs[saveInd].Node.removeFromParent()
        })
        let sequence = SKAction.sequence([waitAction, fadeAction, remove])
        
        orbs[saveInd].Node.run(sequence, completion:{
            //self.orbs[saveInd].type = Type.other
            //self.orbs[saveInd].Node.removeFromParent()
            let skyfallAction = self.skyfall(ind: finishedIndices)
            for action in skyfallAction{
                self.run(action)
                }
        })
        
        // delay removing combo labels so user can see how many combos they made
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            for label in labels{
                label.removeFromParent()
            }
        }
        
        // TODO: find matches after skyfall, then get rid of orbs and skyfall again
        matchedSet = findMatches(orbs: orbs)
    }
    
    
    /**
        Function that intializes game and board
     */
    override func didMove(to view: SKView) {
        let tileBackground = childNode(withName: "BGTiles") as? SKTileMapNode
        self.tileBackground = tileBackground
        self.physicsWorld.contactDelegate = self
        
        // initialize all orbs in the board
        for row in 0...4{
            for column in 0...5{
                orbs.append(orbCreate(tileBackground: self.tileBackground, pos: tileBackground!.centerOfTile(atColumn: column, row: row)))
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
        
        if(row >= 5 || col >= 6){
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
