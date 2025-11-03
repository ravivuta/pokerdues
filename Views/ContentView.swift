//
//  ContentView.swift
//  Poker Dues
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showingAddPlayer = false
    @State private var newPlayerName = ""
    @State private var newPlayerNet: String = ""
    @State private var showingStats = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Players List
                if viewModel.players.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No players added yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Tap + to add players")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.players) { player in
                            PlayerRow(player: player, viewModel: viewModel)
                        }
                        .onDelete(perform: viewModel.removePlayer)
                        
                        // Grand Total Row
                        HStack {
                            Text("Grand Total")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.2f", grandTotal))
                                .font(.headline)
                                .foregroundColor(grandTotal == 0 ? .green : .red)
                        }
                        .padding(.vertical, 8)
                    }
                    .listStyle(PlainListStyle())
                }
                
                Divider()
                
                // Settlement Transactions
                if !viewModel.transactions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Settlement Transactions")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(viewModel.transactions) { transaction in
                                    HStack {
                                        Text(transaction.description)
                                            .font(.system(.body, design: .monospaced))
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                        .frame(maxHeight: 200)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        showingAddPlayer = true
                    }) {
                        Label("Add Player", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.calculate()
                    }) {
                        Label("Calculate", systemImage: "calculator")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.players.isEmpty ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.players.isEmpty)
                    
                    Button(action: {
                        viewModel.clearGameData()
                    }) {
                        Label("Clear", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.players.isEmpty)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("Poker Dues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingStats = true
                    }) {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlayer) {
                AddPlayerView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingStats) {
                StatsView(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
    
    private var grandTotal: Double {
        viewModel.players.reduce(0.0) { $0 + $1.net }
    }
}

struct PlayerRow: View {
    let player: Player
    @ObservedObject var viewModel: GameViewModel
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedBuyIn: String = ""
    @State private var editedFinalBalance: String = ""
    @State private var activeInput: GameViewModel.PlayerValueInput?
    @State private var inputAmount: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.headline)
                    Text("Net: \(formatted(player.net))")
                        .font(.subheadline)
                        .foregroundColor(player.net >= 0 ? .green : .red)
                }
                Spacer()
                Button(action: toggleEditing) {
                    Image(systemName: isEditing ? "xmark.circle" : "pencil")
                        .foregroundColor(.blue)
                }
                .disabled(activeInput != nil)
            }
            
            HStack(spacing: 16) {
                valueTag(title: "Buy-In", amount: player.buyIn, background: Color.red.opacity(0.15))
                valueTag(title: "Final", amount: player.finalBalance, background: Color.green.opacity(0.15))
            }
            
            if !isEditing {
                HStack(spacing: 12) {
                    Button(action: { startInput(.buyIn) }) {
                        Label("Add Buy-In", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { startInput(.finalBalance) }) {
                        Label("Add Final", systemImage: "banknote")
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if let activeInput {
                HStack(spacing: 8) {
                    TextField(activeInput == .buyIn ? "Buy-In Amount" : "Final Balance Amount", text: $inputAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 160)
                    Button("Save") {
                        saveInput(activeInput)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(Double(inputAmount) == nil)
                    Button("Cancel") {
                        cancelInput()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Name", text: $editedName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack(spacing: 12) {
                        TextField("Buy-In", text: $editedBuyIn)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Final Balance", text: $editedFinalBalance)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack(spacing: 12) {
                        Button("Save Changes") {
                            saveEdits()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canSaveEdits)
                        Button("Cancel") {
                            cancelEditing()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .onChange(of: player.buyIn) { _ in
            refreshEditedFieldsIfNeeded()
        }
        .onChange(of: player.finalBalance) { _ in
            refreshEditedFieldsIfNeeded()
        }
        .onChange(of: player.name) { _ in
            refreshEditedFieldsIfNeeded()
        }
        .onAppear {
            syncEditedFields()
        }
    }
    
    private var canSaveEdits: Bool {
        guard Double(editedBuyIn) != nil, Double(editedFinalBalance) != nil else { return false }
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty
    }
    
    private func saveEdits() {
        guard let buyInValue = Double(editedBuyIn),
              let finalBalanceValue = Double(editedFinalBalance) else { return }
        let success = viewModel.updatePlayer(player, name: editedName, buyIn: buyInValue, finalBalance: finalBalanceValue)
        if success {
            isEditing = false
        }
    }
    
    private func toggleEditing() {
        if isEditing {
            cancelEditing()
        } else {
            syncEditedFields()
            isEditing = true
        }
    }
    
    private func cancelEditing() {
        isEditing = false
        syncEditedFields()
    }
    
    private func startInput(_ type: GameViewModel.PlayerValueInput) {
        activeInput = type
        inputAmount = ""
    }
    
    private func saveInput(_ type: GameViewModel.PlayerValueInput) {
        guard let amount = Double(inputAmount) else { return }
        if viewModel.applyAmount(to: player, amount: amount, inputType: type) {
            cancelInput()
        }
    }
    
    private func cancelInput() {
        activeInput = nil
        inputAmount = ""
    }
    
    private func syncEditedFields() {
        editedName = player.name
        editedBuyIn = formatted(player.buyIn)
        editedFinalBalance = formatted(player.finalBalance)
    }

    private func refreshEditedFieldsIfNeeded() {
        if !isEditing {
            syncEditedFields()
        }
    }
    
    private func formatted(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
    
    @ViewBuilder
    private func valueTag(title: String, amount: Double, background: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formatted(amount))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(background)
        .cornerRadius(8)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

