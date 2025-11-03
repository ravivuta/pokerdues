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
    
    func addPlayer(name: String, net: Double) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let player = Player(name: trimmedName, net: net)
        players.append(player)
        savePlayers()
    }
    
    func removePlayer(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
        savePlayers()
    }
    
    func updatePlayer(_ player: Player, name: String, net: Double) {
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index].name = name.trimmingCharacters(in: .whitespaces)
            players[index].net = net
            savePlayers()
        }
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
        
        saveOverallStats()
    }
    
    func clearGameData() {
        players = []
        transactions = []
        savePlayers()
    }
    
    func clearStats() {
        overallStats = []
        saveOverallStats()
    }
    
    // MARK: - Data Persistence
    
    private func savePlayers() {
        if let encoded = try? JSONEncoder().encode(players) {
            UserDefaults.standard.set(encoded, forKey: playersKey)
        }
    }
    
    private func saveOverallStats() {
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

