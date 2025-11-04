//
//  PlayerHistoryView.swift
//  Poker Dues
//
//  Created on 2024
//

import SwiftUI

struct PlayerHistoryView: View {
    @ObservedObject var viewModel: GameViewModel
    let playerID: UUID
    @Environment(\.dismiss) private var dismiss
    
    private var player: Player? {
        viewModel.players.first { $0.id == playerID }
    }
    
    private var history: [PlayerTransaction] {
        guard let player else { return [] }
        return player.transactionHistory.sorted(by: { $0.date > $1.date })
    }
    
    private var title: String {
        guard let player else { return "History" }
        return "\(player.name) History"
    }
    
    var body: some View {
        NavigationView {
            Group {
                if history.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No transactions yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Run a settlement to record player transactions.")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemGroupedBackground))
                } else {
                    List(history) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(description(for: entry))
                                    .font(.headline)
                                Spacer()
                                Text(amountText(for: entry))
                                    .font(.headline)
                                    .foregroundColor(entry.role == .received ? .green : .red)
                            }
                            Text(entry.date, format: .dateTime.day().month().year().hour().minute())
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func description(for entry: PlayerTransaction) -> String {
        switch entry.role {
        case .paid:
            return "Paid \(entry.counterpartName)"
        case .received:
            return "Received from \(entry.counterpartName)"
        }
    }
    
    private func amountText(for entry: PlayerTransaction) -> String {
        let amount = entry.role == .paid ? -entry.amount : entry.amount
        return String(format: "%.2f", amount)
    }
}

