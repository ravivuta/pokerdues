//
//  PlayerTransaction.swift
//  Poker Dues
//
//  Created on 2024
//

import Foundation

struct PlayerTransaction: Identifiable, Codable {
    let id: UUID
    let buyIn: Double
    let date: Date
    let note: String?

    init(
        id: UUID = UUID(),
        buyIn: Double,
        date: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.buyIn = buyIn
        self.date = date
        self.note = note
    }
}

