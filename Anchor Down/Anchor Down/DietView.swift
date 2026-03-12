//
//  DietView.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 9/3/26.
//
import SwiftUI

struct QuickAddCaloriesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: SystemSettings
    
    @State private var inputCalories: String = ""
    @State private var isSaving = false

    let quickAmounts = [100, 250, 400, 600]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {

                TextField("0", text: $inputCalories)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .foregroundColor(.cyan)
                
                Text("kcal eaten")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 15) {
                    ForEach(quickAmounts, id: \.self) { amount in
                        Button(action: {
                            inputCalories = "\(amount)"
                        }) {
                            Text("+\(amount)")
                                .fontWeight(.bold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(Color.cyan.opacity(0.2))
                                .foregroundColor(.cyan)
                                .cornerRadius(10)
                        }
                    }
                }
                
                Spacer()

                Button(action: saveCalories) {
                    Text(isSaving ? "Logging..." : "Log Meal")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .disabled(inputCalories.isEmpty || isSaving)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Log Calories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveCalories() {
        guard let calories = Double(inputCalories) else { return }
        isSaving = true
        
        settings.healthManager.saveDietaryCalories(calories: calories) { success in
            isSaving = false
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    QuickAddCaloriesView()
}
