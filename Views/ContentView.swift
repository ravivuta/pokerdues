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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                TextField("Name", text: $editedName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    TextField("Buy-In", text: $editedBuyIn)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    TextField("Final Balance", text: $editedFinalBalance)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
                if let buyInValue = Double(editedBuyIn), let finalBalanceValue = Double(editedFinalBalance) {
                    Text("Net: \(String(format: "%.2f", finalBalanceValue - buyInValue))")
                        .font(.caption)
                        .foregroundColor(finalBalanceValue - buyInValue >= 0 ? .green : .red)
                }
                HStack {
                    Button("Save") {
                        guard let buyInValue = Double(editedBuyIn),
                              let finalBalanceValue = Double(editedFinalBalance) else { return }
                        let didUpdate = viewModel.updatePlayer(player, name: editedName, buyIn: buyInValue, finalBalance: finalBalanceValue)
                        if didUpdate {
                            isEditing = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Cancel") {
                        resetEdits()
                        isEditing = false
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(.headline)
                        Text("Buy-In: \(String(format: "%.2f", player.buyIn))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Final: \(String(format: "%.2f", player.finalBalance))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "Net: %.2f", player.net))
                            .font(.subheadline)
                            .foregroundColor(player.net >= 0 ? .green : .red)
                    }
                    Spacer()
                    Button(action: {
                        populateEdits()
                        isEditing = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func populateEdits() {
        editedName = player.name
        editedBuyIn = String(format: "%.2f", player.buyIn)
        editedFinalBalance = String(format: "%.2f", player.finalBalance)
    }
    
    private func resetEdits() {
        populateEdits()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

