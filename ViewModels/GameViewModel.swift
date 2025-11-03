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
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let index = players.firstIndex(where: { normalizedName($0.name) == normalizedName(trimmedName) }) {
            players[index].net += net
        } else {
            let player = Player(name: trimmedName, net: net)
            players.append(player)
        }
        
        mergePlayersByNameInPlace()
        saveData()
    }
    
    func removePlayer(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
        saveData()
    }
    
    func updatePlayer(_ player: Player, name: String, net: Double) {
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            players[index].net = net
            mergePlayersByNameInPlace()
            saveData()
        }
    }
    
    func calculate() {
        // Clear previous transactions
        transactions = []
        errorMessage = nil
        
        // Filter out blank players
        let validPlayers = players
            .map { player -> Player in
                var normalizedPlayer = player
                normalizedPlayer.name = normalizedPlayer.name.trimmingCharacters(in: .whitespacesAndNewlines)
                return normalizedPlayer
            }
            .filter { !$0.name.isEmpty }
        
        let aggregatedPlayers = aggregatePlayersByName(validPlayers)
        
        guard !aggregatedPlayers.isEmpty else {
            errorMessage = "Please add at least one player"
            showError = true
            return
        }
        
        // Check for "Grand Total" - in original code, it stops processing there
        // We'll just validate the sum instead
        let grandTotal = aggregatedPlayers.reduce(0.0) { $0 + $1.net }
        
        if grandTotal < -1.0 || grandTotal > 1.0 {
            errorMessage = "ERROR: Grand Total must be zero, check your data: \(String(format: "%.2f", grandTotal))"
            showError = true
            return
        }
        
        // Calculate settlements
        guard let calculatedTransactions = SettlementCalculator.calculate(players: aggregatedPlayers) else {
            errorMessage = "ERROR: Grand Total must be zero, check your data"
            showError = true
            return
        }
        
        transactions = calculatedTransactions
        
        // Add to overall stats (matching original behavior: [date, playerName, netAmount])
        for player in aggregatedPlayers {
            overallStats.append(PlayerStat(
                playerName: player.name,
                netAmount: player.net
            ))
        }
        
        players = aggregatedPlayers
        saveData()
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
            players = aggregatePlayersByName(decoded)
        }
        
        // Load overall stats
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode([PlayerStat].self, from: data) {
            overallStats = decoded
        }
    }

    private func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private func aggregatePlayersByName(_ players: [Player]) -> [Player] {
        var aggregated: [String: Player] = [:]
        var orderedKeys: [String] = []
        
        for player in players {
            let trimmedName = player.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmedName.lowercased()
            
            if var existing = aggregated[key] {
                existing.net += player.net
                aggregated[key] = existing
            } else {
                var newPlayer = player
                newPlayer.name = trimmedName
                aggregated[key] = newPlayer
                orderedKeys.append(key)
            }
        }
        
        return orderedKeys.compactMap { aggregated[$0] }
    }
    
    private func mergePlayersByNameInPlace() {
        players = aggregatePlayersByName(players)
    }
}

