//
//  ContentView.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 24/2/26.
//

import SwiftUI

struct HomeView: View {

    @StateObject var settings = SystemSettings()
    
    @Environment(\.scenePhase) var scenePhase
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @State private var showingSettings = false
    
    @AppStorage("startingWeight") private var startingWeight: Double = 0.0
        var body: some View {
            ScrollView {
                ProgressRing(progress: 0.5)
                    .padding(20) 
                
                VStack(alignment: .leading) {
                    Text(Constants.HomeViewTitleString)
                        .font(.headline)
                        .padding(.horizontal)
              
                    LazyVGrid(columns: columns, spacing: 15) {

                        StatCard(
                            title: Constants.StartingWeightString,
                            value: String(format: "%.1f kg", startingWeight),
                            icon: "calendar.badge.clock",
                            alignment: .center
                        )
                            .gridCellColumns(2)
                            .frame(maxWidth: .infinity)
                            
                        
                        PreviousWeightCard()
                        CurrentWeightCard()
                        OverallWeightCard()
                        TrendingWeightCard()
                        CaloriesBurnedCard()
                        TotalStepsCard()
                        StatCard(
                            title: "Body Fat",
                            value: String(format: "%.1f%%", settings.healthManager.bodyFatPercentage),
                            icon: "percent"
                        )
                        .background(bodyFatColor.opacity(0.2))
                        .cornerRadius(15)
                        
                    }
                    .padding(.horizontal)
                }
                
            }
            .environmentObject(settings)
            .onAppear {
                settings.healthManager.requestAuthorization()
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
            }
            .sheet(isPresented: $showingSettings) {
                    SettingsView()
            }
            .environmentObject(settings)
    }

    var bodyFatColor: Color {
        switch settings.healthManager.bodyFatPercentage {
        case ..<13: return .blue
        case 13.1..<17: return .green
        case 17.1..<24: return .orange
        default: return .red
        }
    }
   
}

struct ProgressRing: View {
    var progress: Double
    
    @AppStorage("startDate") private var startDateSaved: Double = Date().timeIntervalSince1970
    @AppStorage("targetDate") private var targetDateSaved: Double = Date().timeIntervalSince1970
    
    var body: some View {
        let calc = ProgressCalculator(
                    start: Date(timeIntervalSince1970: startDateSaved),
                    end: Date(timeIntervalSince1970: targetDateSaved)
                )
        ZStack {

            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 20)
            
            Circle()
                .trim(from: 0, to: calc.progressFraction)
                .stroke(
                    Color(red: 0.45, green: 0.73, blue: 0.65),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack {
                Text("\(calc.currentDay)")
                    .font(.system(size: 48, weight: .bold))
                Text("of \(calc.totalDays) days")
                    .foregroundColor(.gray)
                Text("\(Int(calc.progressFraction * 100))% Complete") // Percentage
                    .foregroundColor(.teal)
                    .font(.caption)
                Text(Constants.DaysToGoString + " \(calc.totalDays - calc.currentDay)")
                    
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

    var totalDays: Int {
        let diff = Calendar.current.dateComponents([.day], from: start, to: end)
        return max(1, diff.day ?? 1)
    }
    var currentDay: Int {
        let diff = Calendar.current.dateComponents([.day], from: start, to: today)
        let day = (diff.day ?? 0) + 1
        return max(1, min(day, totalDays))
    }
    var progressFraction: Double {
        return Double(currentDay) / Double(totalDays)
    }
}

struct OverallWeightCard: View {

    @AppStorage("startingWeight") private var startingWeight: Double = 0.0
    @EnvironmentObject var systemSettings: SystemSettings
    
    var body: some View {
        VStack(alignment: .leading) {
            let weightChange = systemSettings.healthManager.currentWeight - startingWeight
            
            StatCard(title: Constants.WeigthChangeString, value: String(format: "%.1f kg", weightChange), icon: weightChange <= 0 ? "arrow.down.circle.fill" : "arrow,up.circle.fill")
        }

    }
    
}

struct TrendingWeightCard: View {
    @EnvironmentObject var systemSettings: SystemSettings
    
    var body: some View {
        VStack(alignment: .leading) {
            let diff = systemSettings.healthManager.weightDifference
            
            StatCard(
                title: Constants.LatestShiftString,
                value: diff == 0 ? "Steady" : String(format: "%+.1f kg", diff),
                icon: diff > 0 ? "arrow.up.forward" : "arrow.down.forward"
            )
            .foregroundColor(diff < 0 ? .green : (diff > 0 ? .red : .gray))
        }
    }
}

struct CaloriesBurnedCard: View {
    @EnvironmentObject var systemSettings: SystemSettings

    var body: some View {
        let totalCalories = systemSettings.healthManager.todayCalories + systemSettings.healthManager.restingCalories
        
        StatCard(title: Constants.CaloriesBurnedTodayString, value: String(format: "%.0f kcal", totalCalories), icon: "flame.fill")
    }
}

struct TotalStepsCard: View {
    @EnvironmentObject var systemSettings: SystemSettings
    
    var body: some View {

        StatCard(
            title: Constants.TotalStepsString,
            value: "\(Int(systemSettings.healthManager.todaySteps))",
            icon: "shoeprints.fill"
        )
        .foregroundColor(.blue)
    }

}

struct CurrentWeightCard: View {
    @EnvironmentObject var systemSettings: SystemSettings
    
    var body: some View {
        StatCard(title: Constants.CurrentWeightString, value: String(format: "%.1f kg", systemSettings.healthManager.currentWeight), icon: "scalemass")

    }
}

struct PreviousWeightCard: View {
    @EnvironmentObject var systemSettings: SystemSettings
    
    var body: some View {
        StatCard(title: Constants.PreviousWeightString, value: String(format: "%.1f kg", systemSettings.healthManager.previousWeight), icon: "scalemass.fill")
    }
}

struct SettingsView: View {
    @AppStorage("startDate") private var startDateSaved: Double = Date().timeIntervalSince1970
    @AppStorage("targetDate") private var targetDateSaved: Double = Date().addingTimeInterval(8640000).timeIntervalSince1970
    
    @AppStorage("startingWeight") private var startingWeight: Double = 0.0
    @AppStorage("targetWeight") private var targetWeight: Double = 0.0
    
    var body: some View {
        Form {
            Section(header: Text(Constants.JourneyDatesString)) {
                DatePicker(Constants.StartDateString,
                           selection: Binding(get: { Date(timeIntervalSince1970: startDateSaved) },
                                              set: { startDateSaved = $0.timeIntervalSince1970 }),
                           displayedComponents: .date)
                
                DatePicker(Constants.EventDateString,
                           selection: Binding(get: { Date(timeIntervalSince1970: targetDateSaved) },
                                              set: { targetDateSaved = $0.timeIntervalSince1970 }),
                           displayedComponents: .date)
            }
            Section(header: Text(Constants.WeightGoalsString)) {
                HStack {
                    Text(Constants.StartWeightString)
                        Spacer()
                        TextField("0.0", value: $startingWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text(Constants.TargetWeightString)
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

#Preview {

    HomeView()
        .environmentObject(SystemSettings())
}
