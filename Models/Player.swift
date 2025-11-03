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
    var buyIn: Double
    var finalBalance: Double
    
    var net: Double {
        finalBalance - buyIn
    }
    
    init(id: UUID = UUID(), name: String, buyIn: Double, finalBalance: Double) {
        self.id = id
        self.name = name
        self.buyIn = buyIn
        self.finalBalance = finalBalance
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case buyIn
        case finalBalance
        case net
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        if let buyIn = try container.decodeIfPresent(Double.self, forKey: .buyIn),
           let finalBalance = try container.decodeIfPresent(Double.self, forKey: .finalBalance) {
            self.buyIn = buyIn
            self.finalBalance = finalBalance
        } else if let legacyNet = try container.decodeIfPresent(Double.self, forKey: .net) {
            if legacyNet >= 0 {
                buyIn = 0
                finalBalance = legacyNet
            } else {
                buyIn = -legacyNet
                finalBalance = 0
            }
        } else {
            buyIn = 0
            finalBalance = 0
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(buyIn, forKey: .buyIn)
        try container.encode(finalBalance, forKey: .finalBalance)
        try container.encode(net, forKey: .net)
    }
}

