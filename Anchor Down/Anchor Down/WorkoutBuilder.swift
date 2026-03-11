//
//  WorkoutBuilder.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 11/3/26.
//

import SwiftUI
import HealthKit

struct WorkoutBuilderView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: SystemSettings
    
    let selectedDate: Date
    
    // The workout we are actively building
    @State private var workoutTitle: String = "Strength Session"
    @State private var exercises: [LoggedExercise] = []
    
    @State private var showingExerciseSheet = false
    @State private var isSaving = false
    
    // Your custom home gym library
    let exerciseLibrary = [
        "Warmup / Mobility",
        "Dead Bugs",
        "Stretches",
        "Dumbbell Press",
        "Dumbbell Row",
        "Bicep Curls",
        "Tricep Overhead Extension",
        "Deadlift",
        "Squats",
        "Weighted Vest Walk",
        "Rubber Band Work"
    ]
    
    var body: some View {
            NavigationStack {
                ZStack(alignment: .bottom) {
                    
                    // 1. Upgraded from ScrollView to List
                    List {
                        // --- Header Area ---
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Workout for \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Workout Title", text: $workoutTitle)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                        
                        // --- Exercise List with SWIPE TO DELETE ---
                        ForEach($exercises) { $exercise in
                            ExerciseCardView(exercise: $exercise)
                                // These keep your custom dark card look inside the list
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                        }
                        .onDelete(perform: removeExercise) // Native Apple Swipe!
                        
                        // --- Add Exercise Button ---
                        Button(action: { showingExerciseSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Exercise")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6).opacity(0.2))
                            .foregroundColor(.cyan)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                            )
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 120, trailing: 20)) // Bottom padding for Save button
                    }
                    .listStyle(.plain) // Removes grouped list styling
                    .scrollContentBackground(.hidden) // Removes default gray/white list background
                    
                    // --- Floating Save Button ---
                    VStack {
                        Button(action: finishAndSaveWorkout) {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.black)
                                } else {
                                    Text("Finish & Save Workout")
                                }
                            }
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(exercises.isEmpty ? Color.gray : Color.cyan)
                            .foregroundColor(exercises.isEmpty ? .white : .black)
                            .cornerRadius(16)
                        }
                        .disabled(exercises.isEmpty || isSaving)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                }
                .background(Color(red: 0.02, green: 0.05, blue: 0.12).ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.gray)
                    }
                }
                .sheet(isPresented: $showingExerciseSheet) {
                    ExerciseSelectionSheet(library: exerciseLibrary) { selectedName in
                        let newExercise = LoggedExercise(name: selectedName, sets: [ExerciseSet(reps: 0, weight: 0.0)])
                        exercises.append(newExercise)
                    }
                }
            }
        }
    private func finishAndSaveWorkout() {
        isSaving = true
        
        let totalSets = exercises.reduce(0) { $0 + $1.sets.count }
        let estimatedMinutes = Double(max(15, totalSets * 3))
        
        settings.healthManager.saveWorkout(type: .traditionalStrengthTraining, date: selectedDate, durationMinutes: estimatedMinutes) { success in
            isSaving = false
            dismiss()
        }
    }
    private func removeExercise(at offsets: IndexSet) {
            exercises.remove(atOffsets: offsets)
        }
}


struct ExerciseCardView: View {
    @Binding var exercise: LoggedExercise
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .background(Color(.systemGray6).opacity(0.3))
            .cornerRadius(16)
            
            // Sets Rows
            VStack(spacing: 12) {
                HStack {
                    Text("SET").font(.caption).bold().foregroundColor(.gray).frame(width: 40)
                    Text("KG").font(.caption).bold().foregroundColor(.gray).frame(maxWidth: .infinity)
                    Text("REPS").font(.caption).bold().foregroundColor(.gray).frame(maxWidth: .infinity)
                    Text("✓").font(.caption).bold().foregroundColor(.gray).frame(width: 40)
                }
                .padding(.horizontal)
                
                ForEach($exercise.sets.indices, id: \.self) { index in
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                        
                        TextField("0", value: $exercise.sets[index].weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity)
                        
                        TextField("0", value: $exercise.sets[index].reps, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            exercise.sets[index].isCompleted.toggle()
                        }) {
                            Image(systemName: exercise.sets[index].isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(exercise.sets[index].isCompleted ? .green : .gray)
                                .font(.title2)
                        }
                        .frame(width: 40)
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal)
                }
                
                Button(action: {
                    let lastWeight = exercise.sets.last?.weight ?? 0.0
                    exercise.sets.append(ExerciseSet(reps: 0, weight: lastWeight))
                }) {
                    Text("+ Add Set")
                        .font(.subheadline.bold())
                        .foregroundColor(.cyan)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGray6).opacity(0.15))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ExerciseSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    let library: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        NavigationStack {
            List(library, id: \.self) { exercise in
                Button(action: {
                    onSelect(exercise)
                    dismiss()
                }) {
                    Text(exercise)
                        .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
