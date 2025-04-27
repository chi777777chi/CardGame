//
//  CardGame.swift
//  CardGame
//
//  Created by 陳泓齊 on 2025/4/26.
//

import Foundation

// MARK: - 配對結果種類
enum MatchResult {
    case matched
    case notMatched
    case bomb
}

// MARK: - 遊戲核心
class CardGame {
    
    // MARK: - 公開屬性
    private(set) var score = 0
    private(set) var consecutiveMatches = 0
    private(set) var highestConsecutiveMatches = 0
    private(set) var isSecondPhase = false
    private(set) var bombsDefused = false
    private(set) var stepsCount = 0
    
    var cards = [Card]()
    var emojiChoices: [String]
    var emojiDict = [Int: String]()
    var flipIndices = [Int]() // 暫存翻開的兩張牌
    var latestSystemMessage: String?
    // MARK: - 初始化
    init(numberOfPairs requestedPairs: Int,
         emojis: [String],
         totalSlots: Int) {

        let specialCardCount = 4                       // 💣💣🧹🔄
        let pairsAllowed     = (totalSlots - specialCardCount) / 2
        let pairsToUse       = min(requestedPairs, pairsAllowed)

        emojiChoices = []

        // 普通 emoji
        var normalEmojis = emojis.filter { !["💣", "🧹", "🔄"].contains($0) }

        // 隨機挑出需要的對數
        let selected = normalEmojis.shuffled().prefix(pairsToUse)
        for e in selected {
            emojiChoices += [e, e]                     // 每張加成對
        }

        // 功能牌
        emojiChoices += ["💣", "💣"]                   // 兩顆炸彈
        emojiChoices += ["🧹"]                         // 一張拆彈
        emojiChoices += ["🔄"]                         // 一張重洗

        emojiChoices.shuffle()

        for id in 0..<emojiChoices.count {
            cards.append(Card(id: id))
        }
    }



    
    // MARK: - 核心功能
    
    func chooseCard(at index: Int) {
        guard !cards[index].isMatched else { return }
        
        let selectedCard = cards[index]
        
        // ✅ 翻到🔄
        if !isSecondPhase && isResetCard(card: selectedCard) {
            latestSystemMessage = "翻到🔄！已重新整理牌面！"
            resetAndShuffleCards()
            enterSecondPhase()
            return
        }
        
        if let matchIndex = indexOfFirstFlippedCard, matchIndex != index {
            cards[index].isFaceUp = true
            if emoji(for: cards[matchIndex]) == emoji(for: cards[index]) {
                cards[matchIndex].isMatched = true
                cards[index].isMatched = true
            }
            indexOfFirstFlippedCard = nil
        } else {
            for flipDownIndex in cards.indices {
                if !cards[flipDownIndex].isMatched {
                    cards[flipDownIndex].isFaceUp = false
                }
            }
            cards[index].isFaceUp = true
            indexOfFirstFlippedCard = index
        }
    }


    
    func checkMatch(indices: [Int]) -> MatchResult {
        stepsCount += 1
        let firstIndex = indices[0]
        let secondIndex = indices[1]
        
        let firstCard = cards[firstIndex]
        let secondCard = cards[secondIndex]
        
        // 先判斷是不是配對兩張🧹
        if isDefuseCard(card: firstCard) && isDefuseCard(card: secondCard) {
            defuseBombs()
            cards[firstIndex].isMatched = true
            cards[secondIndex].isMatched = true
            return .matched
        }
        
        // 再判斷炸彈配對（還沒拆除）
        if !bombsDefused && isBomb(card: firstCard) && isBomb(card: secondCard) {
            return .bomb
        }
        
        // 普通配對
        if emoji(for: firstCard) == emoji(for: secondCard) {
            cards[firstIndex].isMatched = true
            cards[secondIndex].isMatched = true
            updateScore(matchSuccess: true)
            return .matched
        } else {
            cards[firstIndex].isFaceUp = false
            cards[secondIndex].isFaceUp = false
            updateScore(matchSuccess: false)
            return .notMatched
        }
    }


    func defuseBombs() {
        for index in cards.indices {
            if isBomb(card: cards[index]) {
                if !emojiChoices.isEmpty {
                    emojiDict[cards[index].id] = emojiChoices.removeFirst()
                } else {
                    emojiDict[cards[index].id] = "🐵"
                }
            }
        }
        bombsDefused = true
        latestSystemMessage = "拆彈已拆除！"
    }


    func enterSecondPhase() {
        isSecondPhase = true
        bombsDefused = false
        
        // 把🔄牌轉成第二張🧹
        for index in cards.indices {
            if isResetCard(card: cards[index]) {
                emojiDict[cards[index].id] = "🧹"
            }
        }
    }
    // 只把牌背過來 + 打亂位置，不改 emoji
    func resetAndShuffleCards() {
        for index in cards.indices {
            cards[index].isFaceUp  = false
            cards[index].isMatched = false
        }
        cards.shuffle()            // 牌位置重新排
    }



    func flipAllCards() {
        for index in cards.indices {
            cards[index].isFaceUp = true
            cards[index].isMatched = true
        }
    }
    
    func flipAllCardsUp() {
        for index in cards.indices {
            if !cards[index].isMatched {
                cards[index].isFaceUp.toggle()
            }
        }
    }
    
    func normalPairsMatchedCount() -> Int {
        return cards.filter { $0.isMatched && !isBomb(card: $0) }.count / 2
    }
    
    func isResetCard(card: Card) -> Bool {
        return emoji(for: card) == "🔄"
    }

    func isBomb(card: Card) -> Bool {
        return emoji(for: card) == "💣"
    }
    func isDefuseCard(card: Card) -> Bool {
        return emoji(for: card) == "🧹"
    }

    func emoji(for card: Card) -> String {
        if emojiDict[card.id] == nil {
            emojiDict[card.id] = emojiChoices.removeFirst()
        }
        return emojiDict[card.id]!
    }
    
    func resetAllCards() {
        for index in cards.indices {
            cards[index].isFaceUp = false
            cards[index].isMatched = false
        }
        emojiChoices.shuffle()
        emojiDict.removeAll()
    }

    // MARK: - 私人方法
    
    private var indexOfFirstFlippedCard: Int?
    
    private func updateScore(matchSuccess: Bool) {
        if matchSuccess {
            consecutiveMatches += 1
            if consecutiveMatches > highestConsecutiveMatches {
                highestConsecutiveMatches = consecutiveMatches
            }
            
            score += 10 * consecutiveMatches
            
        }
        else{
            if score > 0{
                score -= 10
            }
        }
            
    }
    
}
