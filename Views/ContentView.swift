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
                        Label("Settle", systemImage: "Play.fill")
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
            .navigationTitle("Player Transactions")
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
    @State private var editedNet: String = ""
    @State private var editedBuyIn: String = ""
    @State private var editedFinalBalance: String = ""
    @State private var showingHistory = false
   
    var body: some View {
        HStack {
            if isEditing {
                TextField("Name", text: $editedName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("+buyIn", text: $editedBuyIn)
                   .textFieldStyle(RoundedBorderTextFieldStyle())
                   .keyboardType(.decimalPad)
                   .frame(width: 75)
                
                TextField("finalBalance", text: $editedFinalBalance)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 75)
                
                Button("Save") {
                    if let buyIn = Double(editedBuyIn), let finalBalance = Double(editedFinalBalance){
                        viewModel.updatePlayer(player, name: editedName, buyIn: buyIn, finalBalance: finalBalance, net: 0)
                        isEditing = false
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    isEditing = false
                }
                .buttonStyle(.bordered)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(.headline)
                    
                    HStack{
                        Text("Buy-Ins:"+String(format: "%.2f", player.buyIn))
                            .font(.footnote)
                            .foregroundColor(.brown)
                        Text("NET:" + String(format: "%.2f", player.net))
                            .font(.footnote)
                            .foregroundColor(player.net >= 0 ? .green : .red)
                        Text("Ending Balance:" + String(format: "%.2f", player.finalBalance))
                            .font(.footnote)
                            .foregroundColor(.brown)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        showingHistory = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.purple)
                    }
                    
                    Button(action: {
                        editedName = player.name
                        editedBuyIn = ""
                        editedFinalBalance = ""
                        isEditing = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingHistory) {
            PlayerHistoryView(viewModel: viewModel, playerID: player.id)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

