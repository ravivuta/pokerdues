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
    @State private var lockedField: LockedField? = nil
    
    private var calculatedNet: Double? {
        guard let buyInValue = Double(buyIn), let finalBalanceValue = Double(finalBalance) else {
            return nil
        }
        return finalBalanceValue - buyInValue
    }
    
    private enum LockedField {
        case buyIn
        case finalBalance
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Information")) {
                    TextField("Player Name", text: $playerName)
                    TextField("Buy-In", text: $buyIn, onEditingChanged: { isEditing in
                        if isEditing && lockedField == nil {
                            lockedField = .finalBalance
                        }
                    })
                        .keyboardType(.decimalPad)
                        .disabled(lockedField == .buyIn)
                    TextField("Final Balance", text: $finalBalance, onEditingChanged: { isEditing in
                        if isEditing && lockedField == nil {
                            lockedField = .buyIn
                        }
                    })
                        .keyboardType(.decimalPad)
                        .disabled(lockedField == .finalBalance)
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

