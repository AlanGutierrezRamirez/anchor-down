//
//  HealthManager.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 3/3/26.
//

import SwiftUI
import Combine
import HealthKit

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var currentWeight: Double = 0.0
    @Published var weightDifference: Double = 0.0
    @Published var previousWeight: Double = 0.0

    func requestAuthorization() {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let basalType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
        let fatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!

        let typesToRead: Set = [weightType, calorieType, stepType, basalType, fatType]
            
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            if success {
                DispatchQueue.main.async {
                    print("✅ All Health permissions granted")
                    self.fetchSignificantTrend()
                    self.fetchCaloriesBurned()
                    self.fetchTodaySteps()
                    self.fetchRestingCalories()
                    self.fetchLatestBodyFat()
                }

            } else {
                print("❌ Authorization failed: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    func fetchSignificantTrend() {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 30, sortDescriptors: [sortDescriptor]) { _, results, _ in
            guard let samples = results as? [HKQuantitySample], samples.count >= 2 else { return }
            
            let weights = samples.map { $0.quantity.doubleValue(for: .gramUnit(with: .kilo)) }
            let current = weights[0]
            var lastDifferentWeight: Double?
            
            for i in 1..<weights.count {
                if weights[i] != current {
                    lastDifferentWeight = weights[i]
                    break
                }
            }
            
            DispatchQueue.main.async {
                self.currentWeight = current
                if let previous = lastDifferentWeight {
                    self.previousWeight = previous
                    self.weightDifference = current - previous
                } else {
                    self.previousWeight = current
                    self.weightDifference = 0.0
                }
            }
        }
        
        
        
        healthStore.execute(query)
    }
    
    @Published var todayCalories: Double = 0.0

    func fetchCaloriesBurned() {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async { self.todayCalories = 0 }
                return
            }
            
            let totalCals = sum.doubleValue(for: HKUnit.kilocalorie())
            
            DispatchQueue.main.async {
                self.todayCalories = totalCals
            }
        }
        healthStore.execute(query)
    }
    
    @Published var todaySteps: Double = 0.0

    func fetchTodaySteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async { self.todaySteps = 0 }
                return
            }
            
            let totalSteps = sum.doubleValue(for: HKUnit.count())
            
            DispatchQueue.main.async {
                self.todaySteps = totalSteps
            }
        }
        healthStore.execute(query)
    }
    
    @Published var restingCalories: Double = 0.0

    func fetchRestingCalories() {
        let basalType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: basalType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            let cals = sum.doubleValue(for: .kilocalorie())
            
            DispatchQueue.main.async {
                self.restingCalories = cals
            }
        }
        healthStore.execute(query)
    }
    
    @Published var currentBMI: Double = 0.0

    @Published var bodyFatPercentage: Double = 0.0

    func fetchLatestBodyFat() {
        guard let fatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: fatType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else {
                print("No body fat data found")
                return
            }
            
            // HealthKit returns 0.25 for 25%, so we use .percent()
            let fatValue = sample.quantity.doubleValue(for: .percent())
            
            DispatchQueue.main.async {
                self.bodyFatPercentage = fatValue * 100
            }
        }
        healthStore.execute(query)
    }
}

