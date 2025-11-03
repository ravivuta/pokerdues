//
//  Player.swift
//  Poker Dues
//
//  Created on 2024
//

import Foundation

struct Player: Identifiable, Codable {
    let id: UUID
    var name: String
    var net: Double
    var buyIn: Double
    var finalBalance: Double
    
    init(id: UUID = UUID(), name: String, buyIn: Double, finalBalance: Double, net: Double) {
        self.id = id
        self.name = name
        self.net = net
        self.buyIn = buyIn
        self.finalBalance = finalBalance
    }
}

