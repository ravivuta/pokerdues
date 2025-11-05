//
//  ContentView.swift
//  Poker Dues
//
//  Created on 2024
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showingAddPlayer = false
    @State private var newPlayerName = ""
    @State private var newPlayerNet: String = ""
    @State private var showingStats = false
    @State private var showingAddBuyIn = false
    @State private var showingAddFinalBalance = false
    @State private var showingHostExpense = false
    @State private var showCopyConfirmation = false
    @State private var isOriginalExpanded = false
    @State private var isAdjustedExpanded = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                playersListView
                Divider()
                transactionsView
                actionButtonsView
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
            .sheet(isPresented: $showingAddBuyIn) {
                AddPlayerValueView(viewModel: viewModel, inputType: .buyIn)
            }
            .sheet(isPresented: $showingAddFinalBalance) {
                AddPlayerValueView(viewModel: viewModel, inputType: .finalBalance)
            }
            .sheet(isPresented: $showingStats) {
                StatsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingHostExpense) {
                HostExpenseView(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .alert("Copied!", isPresented: $showCopyConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Transactions copied to clipboard")
            }
            .onChange(of: viewModel.transactions.count) { _ in
                // When transactions are calculated, set default expansion states
                if !viewModel.originalTransactions.isEmpty {
                    // If there are original transactions (hosting expense exists)
                    // Collapse original, expand adjusted
                    isOriginalExpanded = false
                    isAdjustedExpanded = true
                } else {
                    // If no original transactions (no hosting expense)
                    // Just show adjusted (no collapse needed)
                    isAdjustedExpanded = true
                }
            }
            .onChange(of: viewModel.originalTransactions.count) { _ in
                // When original transactions change, update expansion states
                if !viewModel.originalTransactions.isEmpty {
                    // If there are original transactions (hosting expense exists)
                    // Collapse original, expand adjusted
                    isOriginalExpanded = false
                    isAdjustedExpanded = true
                } else {
                    // If no original transactions (no hosting expense)
                    // Just show adjusted (no collapse needed)
                    isAdjustedExpanded = true
                }
            }
        }
    }
    
    private var grandTotal: Double {
        viewModel.players.reduce(0.0) { $0 + $1.net }
    }
    
    private var playersListView: some View {
        Group {
            if viewModel.players.isEmpty {
                emptyStateView
            } else {
                playersListContent
            }
        }
    }
    
    private var emptyStateView: some View {
        ZStack {
            // Background poker table image
            if let image = UIImage(named: "casino_table") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .opacity(0.3)
            } else {
                // Fallback gradient background if image not found
                LinearGradient(
                    colors: [Color.brown.opacity(0.2), Color.green.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            // Content overlay
            VStack(spacing: 20) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.7))
                Text("No players added yet")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Tap + Player to start playing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground).opacity(0.8))
            .cornerRadius(12)
            .shadow(radius: 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var playersListContent: some View {
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
    
    private var transactionsView: some View {
        Group {
            if !viewModel.transactions.isEmpty || !viewModel.originalTransactions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    transactionsHeader
                    originalTransactionsSection
                    adjustedTransactionsSection
                }
                .background(Color(UIColor.secondarySystemBackground))
            }
        }
    }
    
    private var transactionsHeader: some View {
        HStack {
            Text("Settlement Transactions")
                .font(.headline)
            Spacer()
            Button(action: {
                copyTransactionsToClipboard()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                    Text("Copy")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var originalTransactionsSection: some View {
        Group {
            if !viewModel.originalTransactions.isEmpty {
                Button(action: {
                    withAnimation {
                        isOriginalExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("Original Settlement Transactions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: isOriginalExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                .buttonStyle(PlainButtonStyle())
                
                if isOriginalExpanded {
                    transactionScrollView(transactions: viewModel.originalTransactions, color: Color.gray.opacity(0.1))
                }
            }
        }
    }
    
    private var adjustedTransactionsSection: some View {
        Group {
            if !viewModel.transactions.isEmpty {
                if !viewModel.originalTransactions.isEmpty {
                    Button(action: {
                        withAnimation {
                            isAdjustedExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text("Adjusted Settlement Transactions (after hosting expenses)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: isAdjustedExpanded ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if isAdjustedExpanded || viewModel.originalTransactions.isEmpty {
                    transactionScrollView(transactions: viewModel.transactions, color: Color.blue.opacity(0.1))
                }
            }
        }
    }
    
    private func transactionScrollView(transactions: [Transaction], color: Color) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                    HStack {
                        Text("\(index + 1). \(transaction.description)")
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(color)
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(maxHeight: 150)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // First row: Add Buy-In and Final Balance
            HStack(spacing: 12) {
                buyInButton
                finalBalanceButton
            }
            
            // Second row: Add Player, Settle, Clear
            HStack(spacing: 12) {
                addPlayerButton
                settleButton
                clearButton
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
    
    private var buyInButton: some View {
        Button(action: {
            showingAddBuyIn = true
        }) {
            Label("Buy-In", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.players.isEmpty ? Color.gray : Color.brown)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(viewModel.players.isEmpty)
    }
    
    private var finalBalanceButton: some View {
        Button(action: {
            showingAddFinalBalance = true
        }) {
            Label("Final Balance", systemImage: "equal.circle.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.players.isEmpty ? Color.gray : Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(viewModel.players.isEmpty)
    }
    
    private var addPlayerButton: some View {
        Button(action: {
            showingAddPlayer = true
        }) {
            Label("Player", systemImage: "plus")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    private var settleButton: some View {
        Button(action: {
            showingHostExpense = true
        }) {
            Label("Settle", systemImage: "checkmark")
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.players.isEmpty ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(viewModel.players.isEmpty)
    }
    
    private var clearButton: some View {
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
    
    private func copyTransactionsToClipboard() {
        var textToCopy = ""
        
        // Add original transactions if available
        if !viewModel.originalTransactions.isEmpty {
            textToCopy += "Original Settlement Transactions\n"
            textToCopy += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            for (index, transaction) in viewModel.originalTransactions.enumerated() {
                textToCopy += "\(index + 1). \(transaction.description)\n"
            }
            textToCopy += "\n"
        }
        
        // Add adjusted transactions
        if !viewModel.transactions.isEmpty {
            if !viewModel.originalTransactions.isEmpty {
                textToCopy += "Adjusted Settlement Transactions (after hosting expenses)\n"
            } else {
                textToCopy += "Settlement Transactions\n"
            }
            textToCopy += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            for (index, transaction) in viewModel.transactions.enumerated() {
                textToCopy += "\(index + 1). \(transaction.description)\n"
            }
        }
        
        // Copy to clipboard
        UIPasteboard.general.string = textToCopy.trimmingCharacters(in: .whitespacesAndNewlines)
        showCopyConfirmation = true
    }
}

struct PlayerRow: View {
    let player: Player
    @ObservedObject var viewModel: GameViewModel
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var showingHistory = false
   
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
                   
                    HStack(spacing: 12) {
                        Text(player.name)
                            .font(.headline)
                    }
                    HStack{
                        Text("Buy-Ins:"+String(format: "%.2f", player.buyIn))
                            .font(.footnote)
                            .foregroundColor(.brown)
                        Button(action: {
                            showingHistory = true
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.purple)
                        }
                        Spacer(minLength:4.0)
                        Text("Ending Balance:" + String(format: "%.2f", player.finalBalance))
                            .font(.footnote)
                            .foregroundColor(.brown)
                        Spacer(minLength:4.0)
                        Text("NET:" + String(format: "%.2f", player.net))
                            .font(.footnote)
                            .foregroundColor(player.net >= 0 ? .green : .red)
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

