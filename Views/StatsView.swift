//
//  StatsView.swift
//  Poker Dues
//
//  Created on 2024
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    
    // Aggregate stats by player name and sum their net amounts for current year
    private var aggregatedStats: [(playerName: String, totalNet: Double)] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let yearStats = viewModel.overallStats.filter { stat in
            Calendar.current.component(.year, from: stat.date) == currentYear
        }
        let grouped = Dictionary(grouping: yearStats) { $0.playerName }
        return grouped.map { (playerName, stats) in
            let total = stats.reduce(0.0) { $0 + $1.netAmount }
            return (playerName: playerName, totalNet: total)
        }
        .sorted { $0.totalNet > $1.totalNet }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if aggregatedStats.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No statistics yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Statistics will appear here after calculations")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(aggregatedStats, id: \.playerName) { aggregated in
                            HStack {
                                Text(aggregated.playerName)
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "%.2f", aggregated.totalNet))
                                    .font(.headline)
                                    .foregroundColor(aggregated.totalNet >= 0 ? .green : .red)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Overall Stats - Year")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        viewModel.clearStats()
                    }
                    .disabled(aggregatedStats.isEmpty)
                    .foregroundColor(.red)
                }
            }
        }
    }
}

