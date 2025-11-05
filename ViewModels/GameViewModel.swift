//
//  GameViewModel.swift
//  Poker Dues
//
//  Created on 2024
//

import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    enum PlayerValueInput {
        case buyIn
        case finalBalance
    }
    @Published var players: [Player] = []
    @Published var transactions: [Transaction] = []
    @Published var originalTransactions: [Transaction] = []
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var overallStats: [PlayerStat] = []
    
    @Published var currentGameId: UUID
    
    private let playersKey = "SavedPlayers"
    private let transactionsKey = "SavedTransactions"
    private let statsKey = "OverallStats"
    private let currentGameIdKey = "CurrentGameId"
    private let lastStatsYearKey = "LastStatsYear"
    
    init() {
        // Load or create current game ID
        if let gameIdString = UserDefaults.standard.string(forKey: currentGameIdKey),
           let gameId = UUID(uuidString: gameIdString) {
            currentGameId = gameId
        } else {
            currentGameId = UUID()
            saveCurrentGameId()
        }
        loadData()
        checkAndResetYearlyStats()
    }
    
    @discardableResult
    func addPlayer(name: String, buyIn: Double, finalBalance: Double, inputType: PlayerValueInput? = nil) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        
        if let existingIndex = players.firstIndex(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            guard let inputType = inputType else {
               // presentError("Player names must be unique.")
               return false
            }
            switch inputType {
            case .buyIn:
                players[existingIndex].buyIn += buyIn
                // Record additional buy-in
                recordBuyInHistory(playerId: players[existingIndex].id, buyIn: buyIn)
            case .finalBalance:
                players[existingIndex].finalBalance = finalBalance
            }
            players[existingIndex].net =  players[existingIndex].finalBalance - players[existingIndex].buyIn
            saveData()
            
            return true
        }
        
        let player: Player
        if let inputType = inputType {
            switch inputType {
            case .buyIn:
                player = Player(gameId: currentGameId, name: trimmedName, buyIn: buyIn, finalBalance: 0, net: -buyIn)
            case .finalBalance:
                player = Player(gameId: currentGameId, name: trimmedName, buyIn: 0, finalBalance: finalBalance, net: finalBalance)
            }
        } else {
            player = Player(gameId: currentGameId, name: trimmedName, buyIn: buyIn, finalBalance: finalBalance, net: -buyIn)
        }
        players.append(player)
        // Record initial buy-in after adding player to array
        if buyIn > 0 {
            recordBuyInHistory(playerId: player.id, buyIn: buyIn)
        }
        saveData()
        return true
    }
    
    func removePlayer(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
        saveData()
    }
    
    @discardableResult
    func updatePlayer(_ player: Player, name: String, buyIn: Double, finalBalance: Double, net: Double) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        
        let exists = players.contains {
            $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
        if !exists{
            return false
        }
        if let index = players.firstIndex(where: {$0.name.caseInsensitiveCompare(trimmedName) == .orderedSame}) {
            players[index].name = trimmedName
            // Record additional buy-in if amount is positive
            if buyIn > 0 {
                recordBuyInHistory(playerId: players[index].id, buyIn: buyIn)
                players[index].buyIn += buyIn
            }
            players[index].finalBalance = finalBalance
            players[index].net = finalBalance - players[index].buyIn
            saveData()
            
            return true
        }

        return false
    }
    
    
    func calculate(hostId: UUID? = nil, expense: Double = 0) {
        // Clear previous transactions
        transactions = []
        originalTransactions = []
        errorMessage = nil
        
        // Filter out blank players
        let originalPlayers = players.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        var validPlayers = originalPlayers
        
        guard !validPlayers.isEmpty else {
            errorMessage = "Please add at least one player"
            showError = true
            return
        }
        
        // Calculate original transactions (before expense adjustment)
        let originalGrandTotal = originalPlayers.reduce(0.0) { $0 + $1.net }
        if originalGrandTotal >= -1.0 && originalGrandTotal <= 1.0 {
            if let originalTxs = SettlementCalculator.calculate(players: originalPlayers, gameId: currentGameId) {
                originalTransactions = originalTxs
            }
        }
        
        // Apply host expense adjustments if provided
        if let hostId = hostId, expense > 0 {
            // Get players with positive net amounts (gainers)
            let positiveNetPlayers = validPlayers.filter { $0.net > 0 }
            
            guard !positiveNetPlayers.isEmpty else {
                errorMessage = "No players with positive net amounts to deduct expense from"
                showError = true
                return
            }
            
            // Calculate total positive net amount
            let totalPositiveNet = positiveNetPlayers.reduce(0.0) { $0 + $1.net }
            
            guard totalPositiveNet > 0 else {
                errorMessage = "Total positive net amount must be greater than zero"
                showError = true
                return
            }
            
            // Create mutable copies with adjusted net amounts
            var adjustedPlayers = validPlayers.map { player -> Player in
                var adjustedPlayer = player
                if adjustedPlayer.net > 0 {
                    // Calculate proportional deduction
                    let proportion = adjustedPlayer.net / totalPositiveNet
                    let deduction = expense * proportion
                    adjustedPlayer.net -= deduction
                }
                // Add expense to host player's net
                if adjustedPlayer.id == hostId {
                    adjustedPlayer.net += expense
                }
                return adjustedPlayer
            }
            
            validPlayers = adjustedPlayers
        }
        
        // Check for "Grand Total" - in original code, it stops processing there
        // We'll just validate the sum instead
        let grandTotal = validPlayers.reduce(0.0) { $0 + $1.net }
        
        if grandTotal < -1.0 || grandTotal > 1.0 {
            errorMessage = "ERROR: Grand Total must be zero, check your data: \(String(format: "%.2f", grandTotal))"
            showError = true
            return
        }
        
        // Calculate settlements with adjusted net amounts
        guard let calculatedTransactions = SettlementCalculator.calculate(players: validPlayers, gameId: currentGameId) else {
            errorMessage = "ERROR: Grand Total must be zero, check your data"
            showError = true
            return
        }
        
        transactions = calculatedTransactions
        //recordBuyInHistory(player, buyIn)
        
        // Remove any existing stats for the current game ID before adding new ones
        overallStats.removeAll { $0.gameId == currentGameId }
        
        // Add to overall stats (matching original behavior: [date, playerName, netAmount])
        // Use original net amounts for stats, not adjusted ones
        for player in players.filter({ !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) {
            overallStats.append(PlayerStat(
                gameId: currentGameId,
                playerName: player.name,
                netAmount: player.net
            ))
        }
        
        saveData()
    }
    
    private func presentError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func clearGameData() {
        // Generate new game ID for the new game
        currentGameId = UUID()
        saveCurrentGameId()
        players = []
        transactions = []
        originalTransactions = []
        saveData()
    }
    
    func clearStats() {
        overallStats = []
        saveData()
    }
    
    // MARK: - Data Persistence
    
    private func saveCurrentGameId() {
        UserDefaults.standard.set(currentGameId.uuidString, forKey: currentGameIdKey)
    }
    
    private func saveData() {
        // Load all players from storage
        var allPlayers: [Player] = []
        if let data = UserDefaults.standard.data(forKey: playersKey),
           let decoded = try? JSONDecoder().decode([Player].self, from: data) {
            allPlayers = decoded
        }
        
        // Remove players from current game and add current players
        allPlayers.removeAll { $0.gameId == currentGameId }
        allPlayers.append(contentsOf: players)
        
        // Save all players
        if let encoded = try? JSONEncoder().encode(allPlayers) {
            UserDefaults.standard.set(encoded, forKey: playersKey)
        }
        
        // Load all transactions from storage
        var allTransactions: [Transaction] = []
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
            allTransactions = decoded
        }
        
        // Remove transactions from current game and add current transactions
        allTransactions.removeAll { $0.gameId == currentGameId }
        allTransactions.append(contentsOf: transactions)
        
        // Save all transactions
        if let encoded = try? JSONEncoder().encode(allTransactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
        }
        
        // Save overall stats
        if let encoded = try? JSONEncoder().encode(overallStats) {
            UserDefaults.standard.set(encoded, forKey: statsKey)
        }
    }
    
    private func loadData() {
        // Load all players and filter by current game ID
        if let data = UserDefaults.standard.data(forKey: playersKey),
           let decoded = try? JSONDecoder().decode([Player].self, from: data) {
            players = decoded.filter { $0.gameId == currentGameId }
        }
        
        // Load all transactions and filter by current game ID
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
            transactions = decoded.filter { $0.gameId == currentGameId }
        }
        
        // Load overall stats
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode([PlayerStat].self, from: data) {
            overallStats = decoded
        }
    }
    
    private func checkAndResetYearlyStats() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let lastStatsYear = UserDefaults.standard.integer(forKey: lastStatsYearKey)
        
        // If lastStatsYear is 0, it means this is the first time, so save current year
        if lastStatsYear == 0 {
            UserDefaults.standard.set(currentYear, forKey: lastStatsYearKey)
            return
        }
        
        // If year has changed, clear old year's stats
        if currentYear > lastStatsYear {
            // Filter stats to keep only current year
            let currentYearStats = overallStats.filter { stat in
                Calendar.current.component(.year, from: stat.date) == currentYear
            }
            
            // Update stats with only current year's data
            overallStats = currentYearStats
            
            // Save the updated stats and new year
            saveData()
            UserDefaults.standard.set(currentYear, forKey: lastStatsYearKey)
        }
    }

    private func recordBuyInHistory(playerId: UUID, buyIn: Double) {
        guard buyIn > 0 else { return }
        
        if let playerIndex = players.firstIndex(where: { $0.id == playerId }) {
            let entry = PlayerTransaction(
                buyIn: buyIn,
                date: Date()
            )
            players[playerIndex].transactionHistory.append(entry)
        }
    }
}

