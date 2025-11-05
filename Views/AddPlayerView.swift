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
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case playerName
        case buyIn
        case finalBalance
    }
    
    private var calculatedNet: Double? {
        guard let inputType = activeInputType else { return nil }
        switch inputType {
        case .buyIn:
            guard let amount = Double(buyIn) else { return nil }
            return -amount
        case .finalBalance:
            guard let amount = Double(finalBalance) else { return nil }
            return amount
        }
    }
    
    private enum LockedField {
        case buyIn
        case finalBalance
    }
    
    private var activeInputType: GameViewModel.PlayerValueInput? {
        switch lockedField {
        case .finalBalance:
            return .buyIn
        case .buyIn:
            return .finalBalance
        case .none:
            if !buyIn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .buyIn
            }
            if !finalBalance.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .finalBalance
            }
            return nil
        }
    }
    
    private var isAddDisabled: Bool {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let inputType = activeInputType else { return true }
        switch inputType {
        case .buyIn:
            return Double(buyIn) == nil
        case .finalBalance:
            return Double(finalBalance) == nil
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Information")) {
                    TextField("Player Name", text: $playerName)
                        .focused($focusedField, equals: .playerName)
                    TextField("+Buy-In", text: $buyIn, onEditingChanged: { isEditing in
                        if isEditing && lockedField == nil {
                            lockedField = .finalBalance
                        }
                    })
                        .keyboardType(.decimalPad)
                        .disabled(lockedField == .buyIn)
                        .focused($focusedField, equals: .buyIn)
                    //TextField("Ending Balance", text: $finalBalance, onEditingChanged: { isEditing in
                    //    if isEditing && lockedField == nil {
                    //        lockedField = .buyIn
                    //    }
                    //})
                     //   .keyboardType(.decimalPad)
                     //   .disabled(lockedField == .finalBalance)
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
                    Text("Enter positive numbers only")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Add")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Focus on player name field when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .playerName
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        guard let inputType = activeInputType else { return }
                        let didAdd: Bool
                        switch inputType {
                        case .buyIn:
                            guard let buyInValue = Double(buyIn) else { return }
                            didAdd = viewModel.addPlayer(name: playerName, buyIn: buyInValue, finalBalance: 0, inputType: .buyIn)
                        case .finalBalance:
                            guard let finalBalanceValue = Double(finalBalance) else { return }
                            didAdd = viewModel.addPlayer(name: playerName, buyIn: 0, finalBalance: finalBalanceValue, inputType: .finalBalance)
                        }
                        if didAdd {
                            dismiss()
                        }
                    }
                    .disabled(isAddDisabled)
                }
            }
        }
    }
}

