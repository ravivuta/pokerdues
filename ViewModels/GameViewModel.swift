//
//  GameViewModel.swift
//  Poker Dues
//
//  Created on 2024
//

import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var transactions: [Transaction] = []
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var overallStats: [PlayerStat] = []
    
    private let playersKey = "SavedPlayers"
    private let statsKey = "OverallStats"
    
    init() {
        loadData()
    }
    
    @discardableResult
    func addPlayer(name: String, buyIn: Double, finalBalance: Double) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        
        guard !players.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) else {
            presentError("Player names must be unique.")
            return false
        }
        
        let player = Player(name: trimmedName, buyIn: buyIn, finalBalance: finalBalance)
        players.append(player)
        saveData()
        return true
    }
    
    func removePlayer(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
        saveData()
    }
    
    @discardableResult
    func updatePlayer(_ player: Player, name: String, buyIn: Double, finalBalance: Double) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        
        let duplicateExists = players.contains {
            $0.id != player.id && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
        
        guard !duplicateExists else {
            presentError("Player names must be unique.")
            return false
        }
        
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index].name = trimmedName
            players[index].buyIn = buyIn
            players[index].finalBalance = finalBalance
            saveData()
            return true
        }

        return false
    }
    
    func calculate() {
        // Clear previous transactions
        transactions = []
        errorMessage = nil
        
        // Filter out blank players
        let validPlayers = players.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !validPlayers.isEmpty else {
            errorMessage = "Please add at least one player"
            showError = true
            return
        }
        
        // Check for "Grand Total" - in original code, it stops processing there
        // We'll just validate the sum instead
        let grandTotal = validPlayers.reduce(0.0) { $0 + $1.net }
        
        if grandTotal < -1.0 || grandTotal > 1.0 {
            errorMessage = "ERROR: Grand Total must be zero, check your data: \(String(format: "%.2f", grandTotal))"
            showError = true
            return
        }
        
        // Calculate settlements
        guard let calculatedTransactions = SettlementCalculator.calculate(players: validPlayers) else {
            errorMessage = "ERROR: Grand Total must be zero, check your data"
            showError = true
            return
        }
        
        transactions = calculatedTransactions
        
        // Add to overall stats (matching original behavior: [date, playerName, netAmount])
        for player in validPlayers {
            overallStats.append(PlayerStat(
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
        players = []
        transactions = []
        saveData()
    }
    
    func clearStats() {
        overallStats = []
        saveData()
    }
    
    // MARK: - Data Persistence
    
    private func saveData() {
        // Save players
        if let encoded = try? JSONEncoder().encode(players) {
            UserDefaults.standard.set(encoded, forKey: playersKey)
        }
        
        // Save overall stats
        if let encoded = try? JSONEncoder().encode(overallStats) {
            UserDefaults.standard.set(encoded, forKey: statsKey)
        }
    }
    
    private func loadData() {
        // Load players
        if let data = UserDefaults.standard.data(forKey: playersKey),
           let decoded = try? JSONDecoder().decode([Player].self, from: data) {
            players = decoded
        }
        
        // Load overall stats
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode([PlayerStat].self, from: data) {
            overallStats = decoded
        }
    }
}

