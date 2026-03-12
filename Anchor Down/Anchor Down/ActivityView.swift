//
//  ActivityView.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 4/3/26.
//

import SwiftUI

struct WorkoutDay: Identifiable {
    let id = UUID()
    let date: Date
    var type: String
    var activeMinutes: Int
    var isCompleted: Bool
}
import Foundation

struct ExerciseSet: Identifiable, Codable {
    var id = UUID()
    var reps: Int
    var weight: Double
    var isCompleted: Bool = false
}

struct LoggedExercise: Identifiable, Codable {
    var id = UUID()
    var name: String
    var sets: [ExerciseSet]
}

struct DetailedWorkout: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var title: String
    var exercises: [LoggedExercise]
    var durationMinutes: Int
}

import SwiftUI
import HealthKit

struct ActivityView: View {
    @EnvironmentObject var settings: SystemSettings
    
    @AppStorage("startDate") private var startDateSaved: Double = Date().timeIntervalSince1970
    @AppStorage("targetDate") private var targetDateSaved: Double = Date().addingTimeInterval(8640000).timeIntervalSince1970
    
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showingWorkoutBuilder = false
    
    let rows = Array(repeating: GridItem(.fixed(22), spacing: 6), count: 7)
    let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                VStack(alignment: .leading, spacing: 8) {
                    
                    Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)
                        .foregroundColor(.cyan)
                        .padding(.leading, 30)
                    
                    HStack(spacing: 10) {
                        VStack(spacing: 6) {
                            ForEach(weekdays, id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .frame(height: 22)
                            }
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(rows: rows, spacing: 6) {
                                ForEach(Array(paddedJourneyDates.enumerated()), id: \.offset) { index, optionalDate in
                                    
                                    if let date = optionalDate {
                                        let dayWorkouts = settings.healthManager.workoutHistory[date] ?? []
                                        let isLogged = !dayWorkouts.isEmpty
                                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(isLogged ? Color.cyan : Color.white.opacity(0.05))
                                            .frame(width: 22, height: 22)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                withAnimation { selectedDate = date }
                                            }
                                    } else {
                                        Color.clear.frame(width: 22, height: 22)
                                    }
                                }
                            }
                            .padding(.vertical)
                            .padding(.trailing)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 15) {
                    Text("Selected: \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Divider().background(Color.white.opacity(0.2))
                    
                    if let localWorkout = settings.getWorkout(for: selectedDate) {
                        
                        Text(localWorkout.title)
                            .font(.title3.bold())
                            .foregroundColor(.cyan)
                        
                        ForEach(localWorkout.exercises) { exercise in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name).font(.subheadline.bold())
                                Text("\(exercise.sets.count) sets")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 4)
                        }
                        
                    } else {
                        let workouts = settings.healthManager.workoutHistory[selectedDate] ?? []
                        
                        if workouts.isEmpty {
                            Text("No activity logged for this day.")
                                .foregroundColor(.secondary)
                            
                            Button(action: { showingWorkoutBuilder = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Log Detailed Workout")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cyan)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                            
                        } else {
                            ForEach(workouts, id: \.uuid) { workout in
                                HStack {
                                    StatBox(title: "Session", value: nameFor(workout.workoutActivityType), icon: iconFor(workout.workoutActivityType))
                                    StatBox(title: "Duration", value: "\(Int(workout.duration / 60)) min", icon: "timer")
                                }
                            }
                        }
                    }
                }
                                
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.15))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Consistency")
            .background(Color(red: 0.02, green: 0.05, blue: 0.12).ignoresSafeArea())
            .sheet(isPresented: $showingWorkoutBuilder) {
                WorkoutBuilderView(selectedDate: selectedDate)
                    .environmentObject(settings)
            }
        }
    }
    
    var paddedJourneyDates: [Date?] {
        let start = Date(timeIntervalSince1970: startDateSaved)
        let end = Date(timeIntervalSince1970: targetDateSaved)
        var dates: [Date?] = []
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: start)
        let endOfDay = calendar.startOfDay(for: end)
        
        let weekday = calendar.component(.weekday, from: startOfDay)
        for _ in 1..<weekday { dates.append(nil) }
        
        var currentDate = startOfDay
        while currentDate <= endOfDay {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return dates
    }
    
    private func nameFor(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "Dumbbells"
        case .walking: return "Walking Pad"
        default: return "Workout"
        }
    }
    
    private func iconFor(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "dumbbell.fill"
        case .walking: return "figure.walk"
        default: return "flame.fill"
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon).foregroundColor(.cyan)
                Text(title).font(.caption).foregroundColor(.secondary)
            }
            Text(value).font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
    }
}
#Preview{
    
    ActivityView()
}
