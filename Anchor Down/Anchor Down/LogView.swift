//
//  LogView.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 6/3/26.
//

import SwiftUI

struct LogView: View {
    @StateObject var settings = SystemSettings()
    @AppStorage("startingDate") private var startingDate: Date = Date()
    @State private var dailyLogs: [DailyLog] = []
    
    var groupedLogs: [(Date, [DailyLog])] {
        let dict = Dictionary(grouping: dailyLogs) { log in
            let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: log.date)
            return Calendar.current.date(from: components) ?? log.date
        }
        return dict.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 25, pinnedViews: [.sectionHeaders]) {
                    
                    ForEach(groupedLogs, id: \.0) { weekStart, logsInWeek in
                        Section(header:
                                    WeeklySummaryCard(
                                        weightLost: calculateWeeklyWeightLoss(for: logsInWeek),
                                        fatDropped: calculateWeeklyFatLoss(for: logsInWeek),
                                        totalSteps: logsInWeek.reduce(0) { $0 + $1.steps }
                                    )
                                        .padding(.horizontal)
                        ) {
                            ForEach(logsInWeek.sorted(by: { $0.date > $1.date })) { log in
                                DailyRow(log: log)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 100)
            }
            .background(Color(red: 0.02, green: 0.05, blue: 0.12).ignoresSafeArea())
            .onAppear {
                fetchAllLogsSinceStart()
            }
        }
    }
    func calculateLoss(for logs: [DailyLog]) -> Double {
        guard logs.count > 1 else { return 0.0 }
        let sorted = logs.sorted(by: { $0.date < $1.date })
        return (sorted.first?.weight ?? 0) - (sorted.last?.weight ?? 0)
    }
    func calculateWeeklyWeightLoss(for logs: [DailyLog]) -> Double {

        let sortedLogs = logs.sorted { $0.date < $1.date }

        let validLogs = sortedLogs.filter { $0.weight > 0 }
        
        guard let firstWeight = validLogs.first?.weight,
              let lastWeight = validLogs.last?.weight,
              validLogs.count >= 1 else { return 0.0 }
        
        return validLogs.count > 1 ? firstWeight - lastWeight : 0.0
    }

    func calculateWeeklyFatLoss(for logs: [DailyLog]) -> Double {
        let validLogs = logs.filter { $0.bodyFat > 0 }.sorted { $0.date < $1.date }

        guard validLogs.count >= 2,
              let first = validLogs.first?.bodyFat,
              let last = validLogs.last?.bodyFat else {
            return 0.0
        }

        return first - last
    }
        

}

struct DailyLog: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let steps: Int
    let activeCalories: Int
    let bodyFat: Double
}

struct DailyRow: View {
    let log: DailyLog
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text(log.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.subheadline).bold()
                Text(log.date.formatted(.dateTime.weekday()))
                    .font(.caption2).foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            VStack {
                Text(String(format: "%.1f kg", log.weight))
                    .font(.system(.body, design: .rounded)).bold()
                Text("Weight").font(.caption2).foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack {
                Text("\(log.steps)")
                    .font(.system(.body, design: .rounded)).bold()
                Text("Steps").font(.caption2).foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(log.activeCalories)")
                    .font(.system(.body, design: .rounded)).bold()
                    .foregroundColor(.orange)
                Text("Kcal").font(.caption2).foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.1))
        .cornerRadius(12)
    }
}

struct WeeklySummaryCard: View {
    let weightLost: Double
    let fatDropped: Double
    let totalSteps: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)
                .foregroundColor(.cyan)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(String(format: "%.1f", weightLost)) kg")
                        .font(.title2).bold()
                    Text("Weight Lost").font(.caption)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text(fatDropped, format: .percent.precision(.fractionLength(1)))
                        .font(.title2).bold()
                    Text("Fat Dropped").font(.caption)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("\(totalSteps / 1000)k")
                        .font(.title2).bold()
                    Text("Steps").font(.caption)
                }
            }
        }
        .padding()
        .background(LinearGradient(colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
    }
}


extension LogView {
    func fetchAllLogsSinceStart() {
        let calendar = Calendar.current
        @AppStorage("startDate") var startDateSaved: Double = Date().timeIntervalSince1970
        let start = calendar.startOfDay(for: Date(timeIntervalSince1970: startDateSaved))
        let today = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.day], from: start, to: today)
        let daysPassed = components.day ?? 0
        
        self.dailyLogs = []
        
        for i in 0...daysPassed {
            if let targetDate = calendar.date(byAdding: .day, value: -i, to: today) {
                settings.healthManager.fetchDataForDay(targetDate) { log in
                    DispatchQueue.main.async {
                        self.dailyLogs.append(log)
                        self.dailyLogs.sort { $0.date > $1.date }
                    }
                }
            }
        }
    }
    
    func calculateWeeklyStats() -> (weightLost: Double, fatDropped: Double, totalSteps: Int)? {
        guard dailyLogs.count >= 7 else { return nil }
        let lastWeek = dailyLogs.suffix(7)
        let weightLost = (lastWeek.first?.weight ?? 0) - (lastWeek.last?.weight ?? 0)
        let totalSteps = lastWeek.reduce(0) { $0 + $1.steps }
        return (weightLost, 0.2, totalSteps)
    }
    
}

#Preview {
    LogView()
        .environmentObject(SystemSettings())
}
