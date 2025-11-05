//
//  HostExpenseView.swift
//  Poker Dues
//
//  Created on 2024
//

import SwiftUI

struct HostExpenseView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedHostId: UUID?
    @State private var expenseAmount: String = ""
    @FocusState private var isExpenseFieldFocused: Bool
    
    private var selectedHost: Player? {
        guard let selectedHostId = selectedHostId else { return nil }
        return viewModel.players.first { $0.id == selectedHostId }
    }
    
    private var expenseValue: Double? {
        guard let amount = Double(expenseAmount), amount >= 0 else { return nil }
        return amount
    }
    
    private var isProceedDisabled: Bool {
        // Allow proceeding even without host/expense (expense defaults to 0)
        expenseValue == nil && !expenseAmount.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Host (Optional)")) {
                    Picker("Host", selection: $selectedHostId) {
                        Text("No host").tag(nil as UUID?)
                        ForEach(viewModel.players) { player in
                            Text(player.name).tag(player.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Host Expense (Optional)")) {
                    TextField("Expense Amount (0 for no expense)", text: $expenseAmount)
                        .keyboardType(.decimalPad)
                        .focused($isExpenseFieldFocused)
                    
                    if let expense = expenseValue, expense > 0 {
                        Text("Expense: \(String(format: "%.2f", expense))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Note")) {
                    Text("If host and expense are provided, the expense will be deducted proportionally from players with positive net amounts, benefiting the host. Leave expense as 0 or empty to proceed without host expense.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Host Expense")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isExpenseFieldFocused = true
                }
            }
            .onChange(of: selectedHostId) { _ in
                if selectedHostId != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isExpenseFieldFocused = true
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
                    Button("Proceed") {
                        let hostId = selectedHostId
                        let expense = expenseValue ?? 0
                        
                        // Only apply expense if both host and expense > 0 are provided
                        if let hostId = hostId, expense > 0 {
                            viewModel.calculate(hostId: hostId, expense: expense)
                        } else {
                            // Proceed without host expense
                            viewModel.calculate()
                        }
                        dismiss()
                    }
                    .disabled(isProceedDisabled)
                }
            }
        }
    }
}

