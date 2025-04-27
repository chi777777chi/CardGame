//
//  ViewController.swift
//  CardGame
//
//  Created by 陳泓齊 on 2025/4/26.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet var cardButtons: [UIButton]!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var currentComboLabel: UILabel!
    @IBOutlet weak var highestComboLabel: UILabel!
    @IBOutlet weak var systemMessageLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    
    // MARK: - Timers
    var timer: Timer?
    var secondsElapsed: Int = 0

    // MARK: - Game Setup
    var game: CardGame!

    

    let baseEmojis = [
        "🐶", "🐱", "🐭", "🐹", "🐰",
        "🦊", "🐻", "🐼", "🐨", "🐯",
        "🦁", "🐮", "🐷", "🐸", "🐵",
        "💣",
        "🧹",      // 一張拆彈
        "🔄"       // 一張重新整理
    ]


    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        let totalSlots   = cardButtons.count           // 30
        let specialCards = 4
        let pairsToUse   = (totalSlots - specialCards) / 2

        game = CardGame(numberOfPairs: pairsToUse,
                        emojis: baseEmojis,
                        totalSlots: totalSlots)

        startTimer()
        updateViewFromModel()
    }
    


    // MARK: - IBActions
    @IBAction func cardTapped(_ sender: UIButton) {
        if let buttonIndex = cardButtons.firstIndex(of: sender) {
            // 防止同一張牌點兩次
            if game.flipIndices.contains(buttonIndex) { return }
            
            if game.flipIndices.count < 2 {
                game.chooseCard(at: buttonIndex)
                game.flipIndices.append(buttonIndex)
                updateViewFromModel()
                
                if game.flipIndices.count == 2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let result = self.game.checkMatch(indices: self.game.flipIndices)
                        self.game.flipIndices.removeAll()
                        self.updateViewFromModel()
                        
                        switch result {
                        case .matched:

                            self.checkForWin()
                            self.showSystemMessage("✅ 配對成功")
                        case .notMatched:
                            self.showSystemMessage("❌ 配對失敗")
                        case .bomb:
                            self.showSystemMessage("💥 你引爆了炸彈！遊戲結束！")
                            self.gameOverByBomb()
                        }
	
                    }
                }
            }
        }
    }
    
    @IBAction func flipAllUp(_ sender: UIButton) {
        game.flipAllCardsUp()
        updateViewFromModel()
    }
    
    @IBAction func debugFlipAll(_ sender: UIButton) {
        game.flipAllCards()
        checkForWin()
        updateViewFromModel()
    }
    
    // MARK: - Timer Methods
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        secondsElapsed += 1
        timerLabel.text = "Time: \(secondsElapsed)s"
    }
    

    // MARK: - Game Flow Control
    func checkForWin() {
        if game.normalPairsMatchedCount() >= 15 {
            timer?.invalidate()
            showAlert(title: "恭喜！", message: "你成功完成配對了！🎉\n總用時：\(secondsElapsed)秒")
        }
    }
    

    
    func gameOverByBomb() {
        timer?.invalidate()
        showAlert(title: "💣 BOOM!", message: "配對到炸彈了！遊戲結束！")
    }
    
    func restartGame() {
        let totalSlots   = cardButtons.count
        let specialCards = 4
        let pairsToUse   = (totalSlots - specialCards) / 2

        game = CardGame(numberOfPairs: pairsToUse,
                        emojis: baseEmojis,
                        totalSlots: totalSlots)

        secondsElapsed = 0
        timerLabel.text = "Time: 0s"
        startTimer()
        updateViewFromModel()
    }


    
    // MARK: - UI Update
    func updateViewFromModel() {
        for index in cardButtons.indices {
            let button = cardButtons[index]
            let card = game.cards[index]
            
            if card.isMatched {
                button.setTitle(game.emoji(for: card), for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 50)
                button.backgroundColor = .darkGray
                button.isEnabled = false
            } else {
                if card.isFaceUp {
                    button.setTitle(game.emoji(for: card), for: .normal)
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 70)
                    button.backgroundColor = .white
                } else {
                    button.setTitle("", for: .normal)
                    button.backgroundColor = .systemGray
                }
                button.isEnabled = true
            }
        }
        stepsLabel.text = "Steps: \(game.stepsCount)"
        scoreLabel.text = "Score: \(game.score)"
        currentComboLabel.text = "當前連續配對: \(game.consecutiveMatches)"
        highestComboLabel.text = "最佳連續配對: \(game.highestConsecutiveMatches)"
        
        if let message = game.latestSystemMessage {
                showSystemMessage(message)
                game.latestSystemMessage = nil // 顯示過後清空，不要重複顯示
            }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "再來一局", style: .default, handler: { _ in
            self.restartGame()
        }))
        present(alert, animated: true, completion: nil)
    }
    func showSystemMessage(_ text: String) {
        systemMessageLabel.text = text
        systemMessageLabel.isHidden = false
        
        // 讓訊息2秒後自動消失（可選）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.systemMessageLabel.isHidden = true
        }
    }

}
