//
//  Player.swift
//  Poker Dues
//
//  Created on 2024
//

import Foundation

struct Player: Identifiable, Codable {
    let id: UUID
    let gameId: UUID
    var name: String
    var net: Double
    var buyIn: Double
    var finalBalance: Double
    var transactionHistory: [PlayerTransaction]
    
    init(
        id: UUID = UUID(),
        gameId: UUID,
        name: String,
        buyIn: Double,
        finalBalance: Double,
        net: Double,
        transactionHistory: [PlayerTransaction] = []
    ) {
        self.id = id
        self.gameId = gameId
        self.name = name
        self.net = net
        self.buyIn = buyIn
        self.finalBalance = finalBalance
        self.transactionHistory = transactionHistory
    }
}

