## SliceFrenzyGame_SwiftSpriteKit
| Oyun Başlıyor | Oyun devam ediyor Canlar Bitene Kadar |
|---------|---------|
| ![Video 1](https://github.com/user-attachments/assets/23fe3a20-405c-4970-b4c3-74d73d3cb3c3) | ![Video 2](https://github.com/user-attachments/assets/c73ee8c3-62c0-4604-873c-7d35d3d1c805) |

 <details>
    <summary><h2>Oyunun Amacı</h2></summary>
    Proje Amacı
   Düşmanları vurmak: Oyun, ekrana düşman nesneleri (örneğin, meyveler veya diğer engeller) düşürür. Oyuncunun bu nesneleri dokunarak yok etmesi gerekir. Her başarılı vurma, oyuncuya puan kazandırır.
   Bombaları engellemek: Oyuncu bombalara dokunmamalıdır. Bir bomba oyuncuya çarptığında, can kaybeder ve bu da oyunun ilerleyen aşamalarında daha zor hale gelmesine yol açar. Üç can hakkı bulunur ve canlar sıfıra indiğinde oyun sona erer.
   Puan kazanmak: Her bir düşman yok edildiğinde, oyuncu puan kazanır. Amaç yüksek puan yapmaktır.
   Hayatta kalmak: Canlar sınırlıdır. Oyun sırasında dikkatli olunmalı ve bombalardan kaçınılmalıdır. Oyuncu düşmanlara ve bombalara dokunmadan hayatta kalmayı başarmalıdır
  </details>  

  <details>
    <summary><h2>createEnemy()</h2></summary>
    rastgele bir düşman (meyve veya bomba) oluşturur ve sahneye ekler. Düşmanın başlangıç pozisyonunu ve hareket hızını belirler.
    
    ```
    func createEnemy() {
    if isGameEnded { return }

    let enemyType = Int.random(in: 0...6)

    let enemy: SKSpriteNode

    if enemyType == 0 {
        // Düşman bombaysa
        enemy = SKSpriteNode(imageNamed: "bomb")
        enemy.name = "bomb"
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
    } else {
        // Düşman meyve ise
        enemy = SKSpriteNode(imageNamed: "fruit")
        enemy.name = "enemy"
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
    }

    let randomXPosition = Int.random(in: 64...960)
    enemy.position = CGPoint(x: randomXPosition, y: -128)
    enemy.physicsBody?.velocity = CGVector(dx: Int.random(in: -40...40), dy: Int.random(in: 24...32) * 40)
    enemy.physicsBody?.angularVelocity = 5
    enemy.physicsBody?.collisionBitMask = 0

    addChild(enemy)
    }




    ```
  </details> 

  <details>
    <summary><h2>subtractLife()</h2></summary>
    Oyuncu bir can kaybettiğinde çağrılır. Canlar sıfır olduğunda oyunu bitirir.

    
    ```
     func subtractLife() {
    lives -= 1
    if lives == 0 {
        endGame(triggeredByBomb: false)
    }
    }


    ```
  </details> 

  <details>
    <summary><h2>endGame(triggeredByBomb:)</h2></summary>
     Oyuncu bir can kaybettiğinde çağrılır. Canlar sıfır olduğunda oyunu bitirir.
    
    ```
       func endGame(triggeredByBomb: Bool) {
    if isGameEnded { return }

    isGameEnded = true

    physicsWorld.speed = 0
    isUserInteractionEnabled = false

    if triggeredByBomb {
        for node in children {
            if node.name == "bomb" {
                node.removeFromParent()
            }
        }
    }
}




    
    ```
  </details> 


  <details>
    <summary><h2>updateScore()</h2></summary>
    Oyuncu puan kazandığında çağrılır ve skor etiketi güncellenir.
    
    ```
        func updateScore(by points: Int) {
    score += points
    scoreLabel.text = "Score: \(score)"
     }


    ```
  </details> 

  <details>
    <summary><h2>tossEnemies()</h2></summary>
    Oyuna sürekli olarak yeni düşmanlar eklemek için çağrılır. Zamanlama, oyundaki hız değişimine bağlıdır
    
    ```
        func tossEnemies() {
    if isGameEnded { return }

    gameSpeed += 0.1

    let delay = Double.random(in: 1.0...(2.5 / gameSpeed))
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
        self?.createEnemy()
        self?.tossEnemies()
    }
    }


    ```
  </details> 

  <details>
    <summary><h2>bombSoundEffect()</h2></summary>
    Bombaların sesiyle ilgili bir ses düğümü oluşturur. Bombaya yaklaşıldığında bu ses duyulur.
    
    ```
          func bombSoundEffect() {
    bombSound?.removeFromParent()
    bombSound = SKAudioNode(fileNamed: "bombSound")
    addChild(bombSound!)
    }




    ```
  </details> 

  <details>
    <summary><h2>touchesBegan(_:with:) Metodu</h2></summary>
    Kullanıcı ekrana dokunduğunda eğer oyun bitmişse yeni bir sahne başlatır. Böylece kullanıcı yeni bir oyun oynayabilir.
    
    ```
              override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGamerOver {
            let newScene = GameScene(size: self.size)
            newScene.scaleMode = .aspectFill
            self.view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1.0))
        }
    }




    ```
  </details> 

  <details>
    <summary><h2>touchesBegan()</h2></summary>
    ekrana dokunulduğunda çağrılır. Eğer dokunulan nesne bir meyveyse skor artırılır; bomba ise oyun biter.
    
    ```
       override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)

    for node in nodes(at: location) {
        if node.name == "enemy" {
            updateScore(by: 1)
            node.removeFromParent()
        } else if node.name == "bomb" {
            endGame(triggeredByBomb: true)
        }
    }
    }
    ```
  </details> 


   <details>
    <summary><h2>playExplosionAnimation()</h2></summary>
    bomba patladığında bir patlama animasyonu oynatır ve sahneden kaldırır
    
    ```
      func playExplosionAnimation(at position: CGPoint) {
    let explosion = SKEmitterNode(fileNamed: "Explosion")!
    explosion.position = position
    addChild(explosion)

    let wait = SKAction.wait(forDuration: 2)
    let remove = SKAction.removeFromParent()
    let sequence = SKAction.sequence([wait, remove])
    explosion.run(sequence)
    }

    ```
  </details> 

  


<details>
    <summary><h2>Uygulama Görselleri </h2></summary>
    
    
 <table style="width: 100%;">
    <tr>
        <td style="text-align: center; width: 16.67%;">
            <h4 style="font-size: 14px;">Oyun Basladiktan sonra</h4>
            <img src="https://github.com/user-attachments/assets/7985b363-37c0-40ae-8230-6520d1847921" style="width: 100%; height: auto;">
        </td>
        <td style="text-align: center; width: 16.67%;">
            <h4 style="font-size: 14px;">Oyundan Gorsel</h4>
            <img src="https://github.com/user-attachments/assets/cb0bfc72-8c28-4e57-8e47-bc0ee688429d" style="width: 100%; height: auto;">
        </td>
      <td style="text-align: center; width: 16.67%;">
            <h4 style="font-size: 14px;">Oyuncu Canlarini Kaybetti</h4>
            <img src="https://github.com/user-attachments/assets/dd50232b-7dd7-4f79-8099-e90fb95cfe19" style="width: 100%; height: auto;">
        </td>
    </tr>
</table>
  </details> 
