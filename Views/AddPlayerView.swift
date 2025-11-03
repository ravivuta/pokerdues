//
//  AddPlayerView.swift
//  Poker Dues
//
//  Created on 2024
//

import SwiftUI

struct AddPlayerView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var playerName = ""
    @State private var playerBuyIn: String = ""
    @State private var playerFinalBalance: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Information")) {
                    TextField("Player Name", text: $playerName)
                    TextField("Buy In", text: $playerBuyIn)
                        .keyboardType(.decimalPad)
                    TextField("Final Balance", text: $playerFinalBalance)
                        .keyboardType(.decimalPad)
                    HStack {
                        Text("Net")
                        Spacer()
                        Text(String(format: "%.2f", netAmount))
                            .foregroundColor(netAmount >= 0 ? .green : .red)
                    }
                }
                
                Section(header: Text("Note")) {
                    Text("Net is calculated automatically: Buy In minus Final Balance")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if let buyIn = Double(playerBuyIn), let finalBalance = Double(playerFinalBalance) {
                            viewModel.addPlayer(name: playerName, buyIn: buyIn, finalBalance: finalBalance)
                            dismiss()
                        }
                    }
                    .disabled(playerName.isEmpty || Double(playerBuyIn) == nil || Double(playerFinalBalance) == nil)
                }
            }
        }
    }

    private var netAmount: Double {
        (Double(playerBuyIn) ?? 0) - (Double(playerFinalBalance) ?? 0)
    }
}

