import SwiftUI

// 1. The Missing Struct: This packages all the math cleanly for the view
struct WeeklyLogGroup: Identifiable {
    let id = UUID()
    let weekStart: Date
    let logs: [DailyLog]
    let weightLost: Double
    let fatDropped: Double
    let totalSteps: Int
}

struct LogView: View {
    @EnvironmentObject var settings: SystemSettings
    
    @AppStorage("startingDate") private var startingDate: Date = Date()
    @State private var dailyLogs: [DailyLog] = []
    
    var groupedLogsData: [WeeklyLogGroup] {
        let dict = Dictionary(grouping: dailyLogs) { log in
            let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: log.date)
            return Calendar.current.date(from: components) ?? log.date
        }
        
        return dict.map { (key, logs) in
            WeeklyLogGroup(
                weekStart: key,
                logs: logs.sorted { $0.date > $1.date },
                weightLost: calculateWeeklyWeightLoss(for: logs),
                fatDropped: calculateWeeklyFatLoss(for: logs),
                totalSteps: logs.reduce(0) { $0 + $1.steps }
            )
        }.sorted { $0.weekStart > $1.weekStart }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 25, pinnedViews: [.sectionHeaders]) {
                    
                    ForEach(groupedLogsData) { group in
                        Section(header: headerView(for: group)) {
                            
                            ForEach(group.logs) { log in
                                if log.isToday {
                                    DailyRow(log: DailyLog(
                                        date: log.date,
                                        weight: settings.healthManager.currentWeight,
                                        steps: Int(settings.healthManager.todaySteps),
                                        activeCalories: Int(settings.healthManager.todayCalories),
                                        restingCalories: Int(settings.healthManager.restingCalories),
                                        bodyFat: settings.healthManager.bodyFatPercentage,
                                        dietaryCalories: Int(settings.healthManager.todayDietaryCalories)
                                    ))
                                } else {
                                    DailyRow(log: log)
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 100)
            }
            .background(Color(red: 0.02, green: 0.05, blue: 0.12).ignoresSafeArea())
            .onAppear {
                settings.healthManager.requestAuthorization()
                fetchAllLogsSinceStart()
            }
        }
    }

    @ViewBuilder
    private func headerView(for group: WeeklyLogGroup) -> some View {
        WeeklySummaryCard(
            weightLost: group.weightLost,
            fatDropped: group.fatDropped,
            totalSteps: group.totalSteps
        )
        .padding(.horizontal)
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
                    }
                }
            }
        }
    }
}

struct DailyLog: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let steps: Int
    let activeCalories: Int
    let restingCalories: Int
    let bodyFat: Double
    let dietaryCalories: Int
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var totalCaloriesBurned: Int {
        return activeCalories + restingCalories
    }
    
    var netCalories: Int {
        return dietaryCalories - totalCaloriesBurned
    }
}

struct DailyRow: View {
    let log: DailyLog
    
    var netColor: Color {
        log.netCalories < 0 ? .green : .red
    }
    
    var body: some View {
        VStack(spacing: 16) {

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.date.formatted(.dateTime.day().month(.wide)))
                        .font(.headline)
                    Text(log.date.formatted(.dateTime.weekday(.wide)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f kg", log.weight))
                        .font(.title3.weight(.bold))
                        .foregroundColor(.cyan)
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))

            HStack {
                DailyStatItem(
                    title: "Steps",
                    value: "\(log.steps)",
                    icon: "shoeprints.fill",
                    color: .primary
                )
                
                Spacer()

                DailyStatItem(
                    title: "Eaten",
                    value: "\(log.dietaryCalories)",
                    icon: "fork.knife",
                    color: .green
                )
                
                Spacer()

                DailyStatItem(
                    title: "Burned",
                    value: "\(log.totalCaloriesBurned)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                Spacer()

                DailyStatItem(
                    title: "Net",
                    value: "\(abs(log.netCalories))",
                    icon: log.netCalories < 0 ? "arrow.down.right" : "arrow.up.right",
                    color: netColor
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.15)) // Subtle card background
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct DailyStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color.opacity(0.8))
            
            Text(value)
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 50)
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

#Preview {
    LogView()
        .environmentObject(SystemSettings())
}
