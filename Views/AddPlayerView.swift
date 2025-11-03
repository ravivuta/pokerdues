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
    @State private var buyIn: String = ""
    @State private var finalBalance: String = ""
    @State private var isEditingBuyIn: Bool = false
    @State private var isEditingFinalBalance: Bool = false
    
    private var calculatedNet: Double? {
        guard let buyInValue = Double(buyIn), let finalBalanceValue = Double(finalBalance) else {
            return nil
        }
        return finalBalanceValue - buyInValue
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Information")) {
                    TextField("Player Name", text: $playerName)
                    TextField("Buy-In", text: $buyIn, onEditingChanged: { isEditing in
                        isEditingBuyIn = isEditing
                        if isEditing {
                            isEditingFinalBalance = false
                        }
                    })
                        .keyboardType(.decimalPad)
                        .disabled(isEditingFinalBalance)
                    TextField("Final Balance", text: $finalBalance, onEditingChanged: { isEditing in
                        isEditingFinalBalance = isEditing
                        if isEditing {
                            isEditingBuyIn = false
                        }
                    })
                        .keyboardType(.decimalPad)
                        .disabled(isEditingBuyIn)
                    if let net = calculatedNet {
                        HStack {
                            Text("Net")
                            Spacer()
                            Text(String(format: "%.2f", net))
                                .foregroundColor(net >= 0 ? .green : .red)
                        }
                    }
                }
                
                Section(header: Text("Note")) {
                    Text("Positive = owed money\nNegative = owes money")
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
                        guard let buyInValue = Double(buyIn),
                              let finalBalanceValue = Double(finalBalance) else { return }
                        let didAdd = viewModel.addPlayer(name: playerName, buyIn: buyInValue, finalBalance: finalBalanceValue)
                        if didAdd {
                            dismiss()
                        }
                    }
                    .disabled(playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(buyIn) == nil || Double(finalBalance) == nil)
                }
            }
        }
    }
}

