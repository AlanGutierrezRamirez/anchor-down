//
//  ActivityView.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 4/3/26.
//

import SwiftUI

struct ActivityView: View {
    @StateObject var healthManager = HealthManager()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                VStack(alignment: .leading) {
                    Text("Weekly Momentum")
                        .font(.headline)
                        .foregroundStyle(.cyan)
                    
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.cyan.opacity(0.1))
                        .frame(height: 150)
                        .overlay(Text("Weekly Steps Chart Here").foregroundColor(.secondary))
                }
                .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    StatCard(
                        title: "Active Burn",
                        value: "\(Int(healthManager.todayCalories)) kcal",
                        icon: "flame.fill",
                        alignment: .leading
                    )
                    .background(.ultraThinMaterial)
                    
                    StatCard(
                        title: "Daily Steps",
                        value: "\(Int(healthManager.todaySteps))",
                        icon: "figure.walk",
                        alignment: .leading
                    )
                    .background(.ultraThinMaterial)
                }
                .padding(.horizontal)

                StatCard(
                    title: "Resting Metabolic Rate",
                    value: "\(Int(healthManager.restingCalories)) kcal/day",
                    icon: "heart.text.square.fill",
                    alignment: .center
                )
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Activity Deck")
        .background(Color(red: 0.02, green: 0.05, blue: 0.12).ignoresSafeArea())
    }
}
