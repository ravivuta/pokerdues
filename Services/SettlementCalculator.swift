//
//  SettlementCalculator.swift
//  Poker Dues
//
//  Created on 2024
//

import Foundation

class SettlementCalculator {
    
    /// Calculates settlement transactions to balance all players
    /// - Parameters:
    ///   - players: Array of players with their net amounts (positive = owed money, negative = owes money)
    ///   - gameId: The game ID to associate transactions with
    /// - Returns: Array of transactions needed to settle all debts, or nil if grand total is not zero
    static func calculate(players: [Player], gameId: UUID) -> [Transaction]? {
        // Filter out blank players
        let validPlayers = players.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !validPlayers.isEmpty else { return [] }
        
        // Check if grand total is zero (within 1.0 tolerance to match original logic)
        let grandTotal = validPlayers.reduce(0.0) { $0 + $1.net }
        if grandTotal < -1.0 || grandTotal > 1.0 {
            return nil // Error: Grand Total must be zero
        }
        
        // Create mutable copies of players with their net amounts
        var playerNames = validPlayers.map { $0.name }
        var netAmounts = validPlayers.map { $0.net } //+ validPlayers.map{ $0.finalBalance}
        
        var transactions: [Transaction] = []
        let rows = validPlayers.count
        
        // Algorithm matches original: iterate from highest debt (most negative) backwards
        for i in stride(from: rows - 1, through: 0, by: -1) {
            var j = 0
            
            // While this player owes money (negative net)
            while netAmounts[i] < 0 && j < rows {
                // Find someone who is owed money (positive net)
                if netAmounts[j] > 0 {
                    if netAmounts[i] + netAmounts[j] >= 0 {
                        // Can pay off all debt to one person
                        let payFrom = playerNames[i]
                        let payTo = playerNames[j]
                        let amount = -1 * netAmounts[i]
                        
                        netAmounts[j] = netAmounts[j] + netAmounts[i]
                        netAmounts[i] = 0
                        
                        transactions.append(Transaction(
                            gameId: gameId,
                            payFrom: payFrom,
                            payTo: payTo,
                            amount: amount
                        ))
                    } else {
                        // Can only pay partial amount
                        let payFrom = playerNames[i]
                        let payTo = playerNames[j]
                        let amount = netAmounts[j]
                        
                        netAmounts[i] = netAmounts[i] + netAmounts[j]
                        netAmounts[j] = 0
                        
                        transactions.append(Transaction(
                            gameId: gameId,
                            payFrom: payFrom,
                            payTo: payTo,
                            amount: amount
                        ))
                    }
                }
                j += 1
            }
        }
        
        return transactions
    }
}

