//
//  GameScene.swift
//  Project23
//
//  Created by Eren Elçi on 17.11.2024.
//

import AVFoundation
import SpriteKit

enum ForceBomb {
    case never , always , random
}

enum SequenceType: CaseIterable {
    case oneNoBomb, one, twoWithOneBomb, two, three, four, chain, fastChain
}


class GameScene: SKScene {
    
    var gamescore : SKLabelNode!
    var gameOverNode: SKSpriteNode?
    var score = 0 {
        didSet {
            gamescore.text = "Score: \(score)"
        }
    }
    var livesImages = [SKSpriteNode]()
    var lives = 3
    var activeSliceBG: SKShapeNode!
    var activeSliceFG: SKShapeNode!
    
    var activeSlicePoints = [CGPoint]()
    var isSwooshSoundActive = false
    
    var activeEnemies = [SKSpriteNode]()
    var bombSoundEffect : AVAudioPlayer?
    
    var popupTime = 0.9
    var sequence = [SequenceType]()
    var sequencePosition = 0
    var chainDelay = 3.0
    var nextSequenceQueued = true
    
    var isGameEnded = false
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        physicsWorld.speed = 0.85
        
        creatScore()
        creatLives()
        creatSlices()
        
        sequence = [.oneNoBomb , .oneNoBomb , .twoWithOneBomb , .twoWithOneBomb , .three , .one , .chain]
        
        for _ in 0...1000 {
            if let nextSequence = SequenceType.allCases.randomElement() {
                    sequence.append(nextSequence)
                }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.tossEnemies()
        }
    }
    
    func showGameOver() {
        if let gameOverNode = gameOverNode {
                gameOverNode.removeFromParent()
            }
            
            // Create a new Game Over node
            let node = SKSpriteNode(imageNamed: "gameOver")
            node.position = CGPoint(x: size.width / 2, y: size.height / 2)
            node.zPosition = 10
            node.name = "gameOver"
            addChild(node)
            
            // Store the reference
            gameOverNode = node
    }
    
    
    func creatScore() {
        gamescore = SKLabelNode(fontNamed: "Chalkduster")
        gamescore.horizontalAlignmentMode = .left
        gamescore.fontSize = 48
        addChild(gamescore)
        gamescore.position = CGPoint(x: 8, y: 8)
        score = 0
    }
    
    func creatLives(){
        for i in 0 ..< 3 {
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            addChild(spriteNode)
            livesImages.append(spriteNode)
        }
    }
    
    func creatSlices() {
        activeSliceBG = SKShapeNode()
        activeSliceBG.zPosition = 2
        
        activeSliceFG = SKShapeNode()
        activeSliceFG.zPosition = 3
        
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9
        
        activeSliceFG.strokeColor = UIColor.white
        activeSliceFG.lineWidth = 5
        
        addChild(activeSliceBG)
        addChild(activeSliceFG)
        
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard  isGameEnded == false else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        activeSlicePoints.append(location)
        redawActiveSlice()
        
        if !isSwooshSoundActive {
            playSwooshSound()
        }
        
        let nodesAtPoint = nodes(at: location)

        for case let node as SKSpriteNode in nodesAtPoint {
            if node.name == "enemy" {
                // destroy penguin
                if let emitter = SKEmitterNode(fileNamed: "sliceHitEnemy") {
                    emitter.position = node.position
                    addChild(emitter)
                }
                node.name = ""
                node.physicsBody?.isDynamic = false
                let scaleOut = SKAction.scale(to: 0.001, duration:0.2)
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                let seq = SKAction.sequence([group, .removeFromParent()])
                node.run(seq)
                
                score += 1
                
                if let index = activeEnemies.firstIndex(of: node) {
                    activeEnemies.remove(at: index)
                }
                
                run(SKAction.playSoundFileNamed("whack.caf", waitForCompletion: false))
            } else if node.name == "bomb" {
                // destroy bomb
                guard let bombContainer = node.parent as? SKSpriteNode else { continue }

                    if let emitter = SKEmitterNode(fileNamed: "sliceHitBomb") {
                        emitter.position = bombContainer.position
                        addChild(emitter)
                    }

                    node.name = ""
                    bombContainer.physicsBody?.isDynamic = false

                    let scaleOut = SKAction.scale(to: 0.001, duration: 0.2)
                    let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                    let group = SKAction.group([scaleOut, fadeOut])

                    let seq = SKAction.sequence([group, .removeFromParent()])
                    bombContainer.run(seq)

                    if let index = activeEnemies.firstIndex(of: bombContainer) {
                        activeEnemies.remove(at: index)
                    }

                    run(SKAction.playSoundFileNamed("explosion.caf", waitForCompletion: false))
                    
                    // endGame yerine sadece subtractLife çağırılıyor
                    subtractLife()
            }
        }
    }
    
    func endGame(triggeredByBomb: Bool){
        guard isGameEnded == false else { return }

            isGameEnded = true
            physicsWorld.speed = 0
            isUserInteractionEnabled = false

            // Stop bomb sound
            bombSoundEffect?.stop()
            bombSoundEffect = nil

            // Update the lives images if bomb triggered
            if triggeredByBomb {
                livesImages[0].texture = SKTexture(imageNamed: "sliceLifeGone")
                livesImages[1].texture = SKTexture(imageNamed: "sliceLifeGone")
                livesImages[2].texture = SKTexture(imageNamed: "sliceLifeGone")
            }

            // Show game over screen
            showGameOver()
    }
    
    func playSwooshSound(){
        isSwooshSoundActive = true
        
        let randomNumber = Int.random(in: 1...3)
        let soundName = "swoosh\(randomNumber).caf"
        
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        
        run(swooshSound) { [weak self] in
            self?.isSwooshSoundActive = false
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSliceBG.run(SKAction.fadeOut(withDuration: 0.25))
        activeSliceFG.run(SKAction.fadeOut(withDuration: 0.25))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
           
           let location = touch.location(in: self)
           
           // Ensure the game over node is clickable by bringing it to the front
           if let gameOverNode = gameOverNode {
               gameOverNode.zPosition = 10
           }

           let nodesAtPoint = nodes(at: location)
           
           // Check if the game over node is clicked
           for node in nodesAtPoint {
               if node.name == "gameOver" {
                   print("Game over clicked")
                   restartGame()
                   return
               }
           }
           
           // Handle other touches (like slicing)
           activeSlicePoints.removeAll(keepingCapacity: true)
           activeSlicePoints.append(location)
           
           redawActiveSlice()
           
           activeSliceBG.removeAllActions()
           activeSliceFG.removeAllActions()
           
           activeSliceBG.alpha = 1
           activeSliceFG.alpha = 1
    }
    
    func redawActiveSlice(){
        if activeSlicePoints.count < 2 {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
        
        if activeSlicePoints.count > 12 {
            activeSlicePoints.removeFirst(activeSlicePoints.count - 12)
        }
        
        let path = UIBezierPath()
        path.move(to: activeSlicePoints[0])
        
        for i in 1 ..< activeSlicePoints.count {
            path.addLine(to: activeSlicePoints[i])
        }
        activeSliceBG.path = path.cgPath
        activeSliceFG.path = path.cgPath

    }
    
    func creatEnemy(forceBomb: ForceBomb = .random) {
        let enemy: SKSpriteNode
        
        var enenmyTyp = Int.random(in: 0...6)
        
        if forceBomb == .never {
            enenmyTyp = 1
        } else if forceBomb == .always{
            enenmyTyp = 0
        }
        
        if enenmyTyp == 0 {
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "bombContainer"
            
            let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
            bombImage.name = "bomb"
            enemy.addChild(bombImage)
            
            if bombSoundEffect != nil {
                bombSoundEffect?.stop()
                bombSoundEffect = nil
            }
            
            
            if let path = Bundle.main.url(forResource: "sliceBombFuse", withExtension: "caf") {
                if let sound = try?  AVAudioPlayer(contentsOf: path) {
                    bombSoundEffect = sound
                    sound.play()
                }
            }
            
            if let emitter = SKEmitterNode(fileNamed: "sliceFuse") {
                emitter.position = CGPoint(x: 76, y: 64)
                enemy.addChild(emitter)
            }
            
        } else {
            enemy = SKSpriteNode(imageNamed: "penguin")
            run(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            enemy.name = "enemy"
        }
        
        let randomPosition = CGPoint(x: Int.random(in: 64...960), y: -128)
        enemy.position = randomPosition
        
        let randomAngularVelocity = CGFloat.random(in: -3...3)
        let randomXVelecity: Int
        
        if randomPosition.x < 256 {
            randomXVelecity = Int.random(in: 8...15)
        } else if  randomPosition.x < 512 {
            randomXVelecity = Int.random(in: 3...5)
        } else if randomPosition.x < 768 {
            randomXVelecity = -Int.random(in: 3...5)
        } else {
            randomXVelecity = -Int.random(in: 8...15)
        }
        
        let randomYVelocity = Int.random(in: 24...32)
        
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody?.velocity = CGVector(dx: randomXVelecity * 40, dy: randomYVelocity * 40)
        enemy.physicsBody?.angularVelocity = randomAngularVelocity
        enemy.physicsBody?.collisionBitMask = 0
        
        
        
        
        addChild(enemy)
        activeEnemies.append(enemy)
        
    }
    
    func subtractLife(){
        lives -= 1

            run(SKAction.playSoundFileNamed("wrong.caf", waitForCompletion: false))

            var life: SKSpriteNode

            if lives == 2 {
                life = livesImages[0]
            } else if lives == 1 {
                life = livesImages[1]
            } else {
                life = livesImages[2]
                endGame(triggeredByBomb: false)
            }

            life.texture = SKTexture(imageNamed: "sliceLifeGone")

            life.xScale = 1.3
            life.yScale = 1.3
            life.run(SKAction.scale(to: 1, duration:0.1))
    }
    
    override func update(_ currentTime: TimeInterval) {
        if activeEnemies.count > 0 {
            for (index, node) in activeEnemies.enumerated().reversed() {
                if node.position.y < -140 {
                    node.removeAllActions()

                       if node.name == "enemy" {
                           node.name = ""
                           subtractLife()

                           node.removeFromParent()
                           activeEnemies.remove(at: index)
                       } else if node.name == "bombContainer" {
                           node.name = ""
                           node.removeFromParent()
                           activeEnemies.remove(at: index)
                       }
                }
            }
        } else {
            if !nextSequenceQueued {
                DispatchQueue.main.asyncAfter(deadline: .now() + popupTime) { [weak self] in
                    self?.tossEnemies()
                }

                nextSequenceQueued = true
            }
        }
        
        var bombCount = 0

            for node in activeEnemies {
                if node.name == "bombContainer" {
                    bombCount += 1
                    break
                }
            }

            if bombCount == 0 {
                // no bombs – stop the fuse sound!
                bombSoundEffect?.stop()
                bombSoundEffect = nil
            }
    }
    
    func tossEnemies(){
        guard  isGameEnded == false else { return }
        
        popupTime *= 0.991
        chainDelay *= 0.99
        physicsWorld.speed *= 1.02
        
        let squenceType = sequence[sequencePosition]
        
        switch squenceType {
            case .oneNoBomb:
            creatEnemy(forceBomb: .never)

            case .one:
            creatEnemy()

            case .twoWithOneBomb:
            creatEnemy(forceBomb: .never)
            creatEnemy(forceBomb: .always)

            case .two:
            creatEnemy()
            creatEnemy()

            case .three:
            creatEnemy()
            creatEnemy()
            creatEnemy()

            case .four:
            creatEnemy()
            creatEnemy()
            creatEnemy()
            creatEnemy()

            case .chain:
            creatEnemy()

                DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0)) { [weak self] in self?.creatEnemy() }
                DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 2)) { [weak self] in self?.creatEnemy() }
                DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 3)) { [weak self] in self?.creatEnemy() }
                DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 5.0 * 4)) { [weak self] in self?.creatEnemy() }

            case .fastChain:
            creatEnemy()

                DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0)) { [weak self] in self?.creatEnemy() }
                DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 2)) { [weak self] in self?.creatEnemy() }
                DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 3)) { [weak self] in self?.creatEnemy() }
                DispatchQueue.main.asyncAfter(deadline: .now() + (chainDelay / 10.0 * 4)) { [weak self] in self?.creatEnemy() }
            }

            sequencePosition += 1
            nextSequenceQueued = false
    }
    
    func restartGame() {
        // Reset the game state
        print("Oyun yeniden başlatıldı")
            // Örnek olarak sahneyi yeniden yükleyebilirsiniz
            let newScene = GameScene(size: self.size)
            let transition = SKTransition.fade(withDuration: 1.0)
            self.view?.presentScene(newScene, transition: transition)
    }


    
  
    
    
    
    
}
