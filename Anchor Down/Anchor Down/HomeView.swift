//
//  ContentView.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 24/2/26.
//

import SwiftUI

#Preview {
    HomeView()
}

struct HomeView: View {

    @Environment(\.scenePhase) var scenePhase
    
    let columns = [
        GridItem(.flexible()), // Column 1
        GridItem(.flexible())  // Column 2
    ]
    
    @State private var showingSettings = false // Controls the popup
    
    @StateObject var healthManager = HealthManager()
    @AppStorage("startingWeight") private var startingWeight: Double = 0.0
        var body: some View {
            ScrollView {
                ProgressRing(progress: 0.5)
                    .padding(20) 
                
                VStack(alignment: .leading) {
                    Text("Making Fast") // Section Header
                        .font(.headline)
                        .padding(.horizontal)

                    StatCard(
                            title: "Starting Weight",
                            value: String(format: "%.1f kg", startingWeight),
                            icon: "calendar.badge.clock",
                            alignment: .center
                        )
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .background(Color.blue.opacity(0.1)) // Subtle highlight for the "Anchor" weight
                        .cornerRadius(15)
              
                    LazyVGrid(columns: columns, spacing: 15) {

                        PreviousWeightCard()
                        CurrentWeightCard()
                        OverallWeightCard()
                        TrendingWeightCard()
                        CaloriesBurnedCard()
                        TotalStepsCard()
                    }
                    .padding(.horizontal)
                }

                

                
                
            }
            .onAppear {
                healthManager.requestAuthorization()
            }
            .foregroundStyle(
                LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .fontWeight(.medium)
                        .foregroundColor(.primary)
                    }
                }
            }// This pops up the settings
            .sheet(isPresented: $showingSettings) {
                    SettingsView()
            }
    }
}

struct ProgressRing: View {
    var progress: Double // e.g., 0.01 for 1%
    
    @AppStorage("startDate") private var startDateSaved: Double = Date().timeIntervalSince1970
    @AppStorage("targetDate") private var targetDateSaved: Double = Date().timeIntervalSince1970
    
    var body: some View {
        let calc = ProgressCalculator(
                    start: Date(timeIntervalSince1970: startDateSaved),
                    end: Date(timeIntervalSince1970: targetDateSaved)
                )
        ZStack {
            // Background Circle
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 20)
            
            // The Progress Line
            Circle()
                .trim(from: 0, to: calc.progressFraction) // This is where the magic happens
                .stroke(
                    Color(red: 0.45, green: 0.73, blue: 0.65), // That teal color
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // Start at the top
            
            VStack {
                Text("\(calc.currentDay)") // Current Day
                    .font(.system(size: 48, weight: .bold))
                Text("of \(calc.totalDays) days")
                    .foregroundColor(.gray)
                Text("\(Int(calc.progressFraction * 100))% Complete") // Percentage
                    .foregroundColor(.teal)
                    .font(.caption)
                Text("Days To Go: \(calc.totalDays - calc.currentDay)")
                    
            }
        }
        .frame(width: 250, height: 250)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var alignment: HorizontalAlignment = .leading
    
    var body: some View {
        VStack(alignment: alignment, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.teal)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
               
            }
            Text(value)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
        .background(Color(.systemGray6).opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ProgressCalculator {
    let start: Date
    let end: Date
    let today: Date = Date()

    // 1. How many total days is this journey?
    var totalDays: Int {
        let diff = Calendar.current.dateComponents([.day], from: start, to: end)
        return max(1, diff.day ?? 1)
    }

    // 2. What day are we on right now?
    var currentDay: Int {
        let diff = Calendar.current.dateComponents([.day], from: start, to: today)
        let day = (diff.day ?? 0) + 1
        return max(1, min(day, totalDays))
    }

    // 3. Percentage for the Ring (0.0 to 1.0)
    var progressFraction: Double {
        return Double(currentDay) / Double(totalDays)
    }
}

struct OverallWeightCard: View {

    @AppStorage("startingWeight") private var startingWeight: Double = 0.0
    @StateObject var healthManager = HealthManager()
    
    var body: some View {
        VStack(alignment: .leading) {
            let weightChange = healthManager.currentWeight - startingWeight
            
            StatCard(title: "Weight Change", value: String(format: "%.1f kg", weightChange), icon: weightChange <= 0 ? "arrow.down.circle.fill" : "arrow,up.circle.fill")
        }
        .onAppear {
            print("Dashboard appeared, requesting HealthKit...")
            healthManager.requestAuthorization()
        }
    }
    
}

struct TrendingWeightCard: View {
    @StateObject var healthManager = HealthManager()
    
    var body: some View {
        VStack(alignment: .leading) {
            let diff = healthManager.weightDifference
            
            StatCard(
                title: "Latest Shift",
                value: diff == 0 ? "Steady" : String(format: "%+.1f kg", diff),
                icon: diff > 0 ? "arrow.up.forward" : "arrow.down.forward"
            )
            .foregroundColor(diff < 0 ? .green : (diff > 0 ? .red : .gray))
        }
        .onAppear {
            print("Dashboard appeared, requesting HealthKit...")
            healthManager.requestAuthorization()
        }
    }
}

struct CaloriesBurnedCard: View {
    @StateObject var healthManager = HealthManager()


    var body: some View {
        let totalCalories = healthManager.todayCalories + healthManager.restingCalories
        
        StatCard(title: "Calories Burned Today", value: String(format: "%.0f kcal", totalCalories), icon: "flame.fill")
            .onAppear {
                print("Dashboard appeared, requesting HealthKit...")
                healthManager.requestAuthorization()
            }
    }
}

struct TotalStepsCard: View {
    
    @StateObject var healthManager = HealthManager()
    
    var body: some View {

        StatCard(
            title: "Total Steps",
            value: "\(Int(healthManager.todaySteps))",
            icon: "shoeprints.fill"
        )
        .foregroundColor(.blue)
        .onAppear {
            print("Dashboard appeared, requesting HealthKit...")
            healthManager.requestAuthorization()
        }
        
    }

}

struct CurrentWeightCard: View {
    @StateObject var healthManager = HealthManager()
    
    var body: some View {
        StatCard(title: "Current Weight", value: String(format: "%.1f kg", healthManager.currentWeight), icon: "scalemass")
            .onAppear {
                print("Dashboard appeared, requesting HealthKit...")
                healthManager.requestAuthorization()
            }
    }
}

struct PreviousWeightCard: View {
    @StateObject var healthManager = HealthManager()
    
    var body: some View {
        StatCard(title: "Previous Weight", value: String(format: "%.1f kg", healthManager.previousWeight), icon: "scalemass.fill")
            .onAppear {
                print("Dashboard appeared, requesting HealthKit...")
                healthManager.requestAuthorization()
            }
    }
}

struct SettingsView: View {
    // @AppStorage saves these automatically to the device's UserDefaults
    @AppStorage("startDate") private var startDateSaved: Double = Date().timeIntervalSince1970
    @AppStorage("targetDate") private var targetDateSaved: Double = Date().addingTimeInterval(8640000).timeIntervalSince1970 // Default +100 days
    
    @AppStorage("startingWeight") private var startingWeight: Double = 0.0
    @AppStorage("targetWeight") private var targetWeight: Double = 0.0
    
    var body: some View {
        Form {
            Section(header: Text("Your Journey Dates")) {
                DatePicker("Start Date",
                           selection: Binding(get: { Date(timeIntervalSince1970: startDateSaved) },
                                              set: { startDateSaved = $0.timeIntervalSince1970 }),
                           displayedComponents: .date)
                
                DatePicker("Event Date",
                           selection: Binding(get: { Date(timeIntervalSince1970: targetDateSaved) },
                                              set: { targetDateSaved = $0.timeIntervalSince1970 }),
                           displayedComponents: .date)
            }
            Section(header: Text("Weight Goals")) {
                HStack {
                        Text("Start Weight")
                        Spacer()
                        TextField("0.0", value: $startingWeight, format: .number)
                            .keyboardType(.decimalPad) // Shows only numbers and a dot
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Target Weight")
                        Spacer()
                        TextField("0.0", value: $targetWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundColor(.gray)
                    }
            }
            
        }
    }
}

