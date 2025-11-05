//
//  AddPlayerValueView.swift
//  Poker Dues
//
//  Created on 2024
//

import SwiftUI

struct AddPlayerValueView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    
    let inputType: GameViewModel.PlayerValueInput
    
    @State private var selectedPlayerId: UUID?
    @State private var amount: String = ""
    @FocusState private var isAmountFieldFocused: Bool
    
    private var selectedPlayer: Player? {
        guard let selectedPlayerId = selectedPlayerId else { return nil }
        return viewModel.players.first { $0.id == selectedPlayerId }
    }
    
    private var isAddDisabled: Bool {
        selectedPlayerId == nil || Double(amount) == nil || (Double(amount) ?? 0) <= 0
    }
    
    private var title: String {
        switch inputType {
        case .buyIn:
            return "Add Buy-In"
        case .finalBalance:
            return "Set Final Balance"
        }
    }
    
    private var placeholder: String {
        switch inputType {
        case .buyIn:
            return "Buy-In Amount"
        case .finalBalance:
            return "Final Balance"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Player")) {
                    Picker("Player", selection: $selectedPlayerId) {
                        Text("Select a player").tag(nil as UUID?)
                        ForEach(viewModel.players) { player in
                            Text(player.name).tag(player.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if let player = selectedPlayer {
                    Section(header: Text("Current Info")) {
                        HStack {
                            Text("Current Buy-In:")
                            Spacer()
                            Text(String(format: "%.2f", player.buyIn))
                                .foregroundColor(.brown)
                        }
                        HStack {
                            Text("Current Final Balance:")
                            Spacer()
                            Text(String(format: "%.2f", player.finalBalance))
                                .foregroundColor(.brown)
                        }
                        HStack {
                            Text("Current Net:")
                            Spacer()
                            Text(String(format: "%.2f", player.net))
                                .foregroundColor(player.net >= 0 ? .green : .red)
                        }
                    }
                }
                
                Section(header: Text(inputType == .buyIn ? "Add Buy-In Amount" : "Set Final Balance")) {
                    TextField(placeholder, text: $amount)
                        .keyboardType(.decimalPad)
                        .focused($isAmountFieldFocused)
                    
                    if let amountValue = Double(amount), amountValue > 0, let player = selectedPlayer {
                        let newNet = inputType == .buyIn 
                            ? player.finalBalance - (player.buyIn + amountValue)
                            : amountValue - player.buyIn
                        HStack {
                            Text("New Net:")
                            Spacer()
                            Text(String(format: "%.2f", newNet))
                                .foregroundColor(newNet >= 0 ? .green : .red)
                        }
                    }
                }
                
                Section(header: Text("Note")) {
                    Text(inputType == .buyIn ? "Enter the additional buy-in amount" : "Enter the final balance amount")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedPlayerId) { _ in
                // Focus on amount field when a player is selected
                if selectedPlayerId != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isAmountFieldFocused = true
                    }
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
                        guard let playerId = selectedPlayerId,
                              let amountValue = Double(amount),
                              amountValue > 0 else { return }
                        
                        if let player = viewModel.players.first(where: { $0.id == playerId }) {
                            switch inputType {
                            case .buyIn:
                                viewModel.addPlayer(name: player.name, buyIn: amountValue, finalBalance: player.finalBalance, inputType: .buyIn)
                            case .finalBalance:
                                viewModel.addPlayer(name: player.name, buyIn: 0, finalBalance: amountValue, inputType: .finalBalance)
                            }
                        }
                        dismiss()
                    }
                    .disabled(isAddDisabled)
                }
            }
        }
    }
}

