//
//  PlayerTransaction.swift
//  Poker Dues
//
//  Created on 2024
//

import Foundation

struct PlayerTransaction: Identifiable, Codable {
    enum Role: String, Codable {
        case paid
        case received
    }
    let id: UUID
    let transactionId: UUID
    let counterpartName: String
    let amount: Double
    let role: Role
    let date: Date
    let note: String?

    init(
        id: UUID = UUID(),
        transactionId: UUID,
        counterpartName: String,
        amount: Double,
        role: Role,
        date: Date,
        note: String? = nil
    ) {
        self.id = id
        self.transactionId = transactionId
        self.counterpartName = counterpartName
        self.amount = amount
        self.role = role
        self.date = date
        self.note = note
    }
}

