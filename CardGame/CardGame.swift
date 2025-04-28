//
//  CardGame.swift
//  CardGame
//
//  Created by 陳泓齊 on 2025/4/26.
//

import Foundation

enum MatchResult {
    case matched
    case notMatched
    case bomb
    case timeoutBomb
}


class CardGame {

    private(set) var score = 0
    private(set) var consecutiveMatches = 0
    private(set) var highestConsecutiveMatches = 0
    private(set) var isSecondPhase = false
    private(set) var bombsDefused = false
    private(set) var stepsCount = 0
    private let totalNormalPairs: Int
    private var indexOfFirstFlippedCard: Int?
    
    var cards = [Card]()
    var emojiChoices: [String]
    var emojiDict = [Int: String]()
    var flipIndices = [Int]()
    var latestSystemMessage: String?

    init(numberOfPairs requestedPairs: Int,
         emojis: [String],
         totalSlots: Int) {

        let specialCardCount = 4
        let pairsAllowed     = (totalSlots - specialCardCount) / 2
        let pairsToUse       = min(requestedPairs, pairsAllowed)

        emojiChoices = []
        totalNormalPairs = pairsToUse

        var normalEmojis = emojis.filter { !["💣", "🧹", "🔄"].contains($0) }

        let selected = normalEmojis.shuffled().prefix(pairsToUse)
        for e in selected {
            emojiChoices += [e, e]
        }

        emojiChoices += ["💣", "💣"]
        emojiChoices += ["🧹"]
        emojiChoices += ["🔄"]

        emojiChoices.shuffle()

        for id in 0..<emojiChoices.count {
            cards.append(Card(id: id))
        }
    }

    func chooseCard(at index: Int) {
        guard !cards[index].isMatched else { return }

        if flipIndices.count == 2 {
            let first = flipIndices[0]
            let second = flipIndices[1]
            if !cards[first].isMatched { cards[first].isFaceUp = false }
            if !cards[second].isMatched { cards[second].isFaceUp = false }
            flipIndices.removeAll()
        }

        if !isSecondPhase && isResetCard(card: cards[index]) {
            latestSystemMessage = "🔄 重新整理！"
            indexOfFirstFlippedCard = nil
            flipIndices.removeAll()
            resetAndShuffleCards()
            enterSecondPhase()
            return
        }

        if let first = indexOfFirstFlippedCard, first != index {
            cards[index].isFaceUp = true
            if emoji(for: cards[first]) == emoji(for: cards[index]) {
                cards[first].isMatched = true
                cards[index].isMatched = true
            }
            indexOfFirstFlippedCard = nil
        } else {
            cards[index].isFaceUp = true
            indexOfFirstFlippedCard = index
            stepsCount += 1
        }
    }

    func checkMatch(indices: [Int]) -> MatchResult {
        guard indices.count == 2 else { return .notMatched }

        let firstIndex = indices[0]
        let secondIndex = indices[1]

        let firstCard = cards[firstIndex]
        let secondCard = cards[secondIndex]

        if stepsCount >= 10 && !bombsDefused {
            return .timeoutBomb
        }

        if isDefuseCard(card: firstCard) && isDefuseCard(card: secondCard) {
            defuseBombs()
            cards[firstIndex].isMatched = true
            cards[secondIndex].isMatched = true
            return .matched
        }

        if !bombsDefused && isBomb(card: firstCard) && isBomb(card: secondCard) {
            return .bomb
        }

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
        var replacement: String

        if let firstLeft = emojiChoices.first {
            replacement = firstLeft
            emojiChoices.removeFirst()
        } else {

            replacement = "✨"
        }

        for idx in cards.indices where isBomb(card: cards[idx]) {
            emojiDict[cards[idx].id] = replacement
        }

        bombsDefused        = true
        latestSystemMessage = "拆彈已拆除！"
    }


    func enterSecondPhase() {
        isSecondPhase = true
        bombsDefused = false
        indexOfFirstFlippedCard = nil   

        for index in cards.indices {
            if isResetCard(card: cards[index]) {
                emojiDict[cards[index].id] = "🧹"
            }
        }
    }

    func resetAndShuffleCards() {
        for index in cards.indices {
            cards[index].isFaceUp  = false
            cards[index].isMatched = false
        }
        cards.shuffle()

        indexOfFirstFlippedCard = nil
    }

    func allNormalPairsMatched() -> Bool {
        let normalCards = cards.filter { !isBomb(card: $0) && !isDefuseCard(card: $0) && !isResetCard(card: $0) }
        let matchedCards = normalCards.filter { $0.isMatched }
        return matchedCards.count == normalCards.count
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
