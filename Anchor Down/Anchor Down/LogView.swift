import SwiftUI

struct LogView: View {
    @EnvironmentObject var settings: SystemSettings
    
    @AppStorage("startDate") private var startDateSaved: Double = Date().timeIntervalSince1970
    
    @State private var dailyLogs: [DailyLog] = []
    @State private var groupedLogsData: [WeeklyLogGroup] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 25, pinnedViews: [.sectionHeaders]) {
                    
                    ForEach(groupedLogsData) { group in
                        Section(header: headerView(for: group)) {
                            
                            ForEach(group.logs) { log in
                                if log.isToday {
                                    DailyRow(log: buildTodayLog(from: log))
                                } else {
                                    DailyRow(log: log)
                                }
                            }
                        }
                    }
                }
                .padding(.top)
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
    
    private func buildTodayLog(from log: DailyLog) -> DailyLog {
        return DailyLog(
            date: log.date,
            weight: settings.healthManager.currentWeight,
            steps: Int(settings.healthManager.todaySteps),
            activeCalories: Int(settings.healthManager.todayCalories),
            restingCalories: Int(settings.healthManager.restingCalories),
            bodyFat: settings.healthManager.bodyFatPercentage
        )
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
    
    func calculateWeeklyWeightLoss(for logs: [DailyLog], baseline: Double?) -> Double {
        let validLogs = logs.sorted { $0.date < $1.date }.filter { $0.weight > 0 }
        guard let lastWeight = validLogs.last?.weight else { return 0.0 }
        let startingWeight = baseline ?? validLogs.first?.weight ?? lastWeight
        return startingWeight - lastWeight
    }
    
    func calculateWeeklyFatLoss(for logs: [DailyLog], baseline: Double?) -> Double {
        let validLogs = logs.sorted { $0.date < $1.date }.filter { $0.bodyFat > 0 }
        guard let lastFat = validLogs.last?.bodyFat else { return 0.0 }
        let startingFat = baseline ?? validLogs.first?.bodyFat ?? lastFat
        return startingFat - lastFat
    }
    
    func fetchAllLogsSinceStart() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = Date(timeIntervalSince1970: startDateSaved)
        
        let components = calendar.dateComponents([.day], from: start, to: today)
        let daysPassed = min(components.day ?? 0, 365)
        
        var tempLogs: [DailyLog] = []
        let fetchGroup = DispatchGroup()
        
        for i in 0...daysPassed {
            if let targetDate = calendar.date(byAdding: .day, value: -i, to: today) {
                
                fetchGroup.enter()
                settings.healthManager.fetchDataForDay(targetDate) { log in
                    DispatchQueue.main.async {
                        tempLogs.append(log)
                        fetchGroup.leave()
                    }
                }
            }
        }
        
        fetchGroup.notify(queue: .main) {
            let sortedLogs = tempLogs.sorted { $0.date > $1.date }
            self.dailyLogs = sortedLogs
            
            DispatchQueue.global(qos: .userInitiated).async {
                let processedGroups = self.buildWeeklyGroups(from: sortedLogs)
                DispatchQueue.main.async {
                    self.groupedLogsData = processedGroups
                }
            }
        }
    }
    
    func buildWeeklyGroups(from logs: [DailyLog]) -> [WeeklyLogGroup] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        
        let dict = Dictionary(grouping: logs) { log in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: log.date)
            return calendar.date(from: components) ?? log.date
        }
        
        return dict.map { (weekStart, weekLogs) in
            let priorLogs = logs.filter { $0.date < weekStart }.sorted { $0.date > $1.date }
            let baselineWeight = priorLogs.first(where: { $0.weight > 0 })?.weight
            let baselineFat = priorLogs.first(where: { $0.bodyFat > 0 })?.bodyFat
            
            return WeeklyLogGroup(
                weekStart: weekStart,
                logs: weekLogs.sorted { $0.date > $1.date },
                weightLost: calculateWeeklyWeightLoss(for: weekLogs, baseline: baselineWeight),
                fatDropped: calculateWeeklyFatLoss(for: weekLogs, baseline: baselineFat),
                totalSteps: weekLogs.reduce(0) { $0 + $1.steps }
            )
        }.sorted { $0.weekStart > $1.weekStart }
    }
}

struct DailyLog: Identifiable {
    var id: Date { date }
    let date: Date
    let weight: Double
    let steps: Int
    let activeCalories: Int
    let restingCalories: Int
    let bodyFat: Double
    
    var isToday: Bool { Calendar.current.isDateInToday(date) }
    var totalCaloriesBurned: Int { activeCalories + restingCalories }
    var fatMass: Double { weight * (bodyFat / 100.0) }
}

struct WeeklyLogGroup: Identifiable {
    var id: Date { weekStart }
    let weekStart: Date
    let logs: [DailyLog]
    let weightLost: Double
    let fatDropped: Double
    let totalSteps: Int
}

struct DailyRow: View {
    let log: DailyLog
    
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
            
            Divider().background(Color.gray.opacity(0.3))
        
            HStack {
                DailyStatItem(title: "Steps", value: "\(log.steps)", icon: "shoeprints.fill", color: .primary)
                Spacer()
                DailyStatItem(title: "Burned", value: "\(log.totalCaloriesBurned)", icon: "flame.fill", color: .orange)
                Spacer()
                DailyStatItem(title: "Fat %", value: String(format: "%.1f%%", log.bodyFat), icon: "percent", color: .pink)
                Spacer()
                DailyStatItem(title: "Fat Mass", value: String(format: "%.1f kg", log.fatMass), icon: "drop.fill", color: .red)
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.15))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
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
            Image(systemName: icon).font(.caption).foregroundColor(color.opacity(0.8))
            Text(value).font(.system(.subheadline, design: .rounded).bold()).foregroundColor(color)
            Text(title).font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
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
                    Text("\(String(format: "%.1f", fatDropped))%")
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
