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
    @Published var todayDietaryCalories: Double = 0.0

    func requestAuthorization() {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let basalType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
        let fatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
        let workoutType = HKObjectType.workoutType()
        
        let typesToRead: Set = [weightType, calorieType, stepType, basalType, fatType, workoutType]

        let typesToWrite: Set = [
                HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!, workoutType
            ]

        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            if success {
                DispatchQueue.main.async {
                    print("✅ All Health permissions granted")
                    self.fetchSignificantTrend()
                    self.fetchCaloriesBurned()
                    self.fetchTodaySteps()
                    self.fetchRestingCalories()
                    self.fetchLatestBodyFat()
                    self.fetchTodayDietaryCalories()
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
            
            let fatValue = sample.quantity.doubleValue(for: .percent())
            
            DispatchQueue.main.async {
                self.bodyFatPercentage = fatValue * 100
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchStatistics(for identifier: HKQuantityTypeIdentifier, predicate: NSPredicate, unit: HKUnit, completion: @escaping (Double) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: identifier)!
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let sum = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
            completion(sum)
        }
        healthStore.execute(query)
    }
    
    private func fetchMostRecentSample(for identifier: HKQuantityTypeIdentifier, predicate: NSPredicate, unit: HKUnit, completion: @escaping (Double) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: identifier)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            let quantity = (results?.first as? HKQuantitySample)?.quantity
            let value = quantity?.doubleValue(for: unit) ?? 0
            completion(value)
        }
        healthStore.execute(query)
    }
    
    func fetchDataForDay(_ date: Date, completion: @escaping (DailyLog) -> Void) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let dailyPredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let historicalPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: end, options: .strictEndDate)
        
        fetchStatistics(for: .stepCount, predicate: dailyPredicate, unit: .count()) { steps in
            self.fetchStatistics(for: .activeEnergyBurned, predicate: dailyPredicate, unit: .kilocalorie()) { calories in
                self.fetchStatistics(for: .basalEnergyBurned, predicate: dailyPredicate, unit: .kilocalorie()) { resting in
                    
                    // 🚨 Use the HISTORICAL predicate for Body Mass and Fat! 🚨
                    self.fetchMostRecentSample(for: .bodyMass, predicate: historicalPredicate, unit: .gramUnit(with: .kilo)) { weight in
                        self.fetchMostRecentSample(for: .bodyFatPercentage, predicate: historicalPredicate, unit: .percent()) { fatFraction in
                            
                            let log = DailyLog(
                                date: date,
                                weight: weight,
                                steps: Int(steps),
                                activeCalories: Int(calories),
                                restingCalories: Int(resting),
                                bodyFat: fatFraction * 100
                            )
                            completion(log)
                        }
                    }
                }
            }
        }
    }
    
    func fetchTodayDietaryCalories() {
        let dietaryType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: dietaryType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let totalCals = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0
            
            DispatchQueue.main.async {
                self.todayDietaryCalories = totalCals
            }
        }
        healthStore.execute(query)
    }
    
    func saveDietaryCalories(calories: Double, completion: @escaping (Bool) -> Void) {
        guard let dietaryType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            completion(false)
            return
        }
        
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        
        let sample = HKQuantitySample(type: dietaryType, quantity: quantity, start: Date(), end: Date())

        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    @Published var workoutHistory: [Date: [HKWorkout]] = [:]

    func fetchWorkouts(since startDate: Date) {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let workouts = samples as? [HKWorkout] else { return }
            
            var grouped: [Date: [HKWorkout]] = [:]
            let calendar = Calendar.current
            
            for workout in workouts {
                let day = calendar.startOfDay(for: workout.startDate)
                grouped[day, default: []].append(workout)
            }
            
            DispatchQueue.main.async {
                self.workoutHistory = grouped
            }
        }
        healthStore.execute(query)
    }

    func saveWorkout(type: HKWorkoutActivityType, date: Date, durationMinutes: Double, completion: @escaping (Bool) -> Void) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = type
        configuration.locationType = .unknown
        
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        
        let endDate = date.addingTimeInterval(durationMinutes * 60)
        
        builder.beginCollection(withStart: date) { success, error in
            guard success else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            builder.endCollection(withEnd: endDate) { success, error in
                guard success else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }

                builder.finishWorkout { workout, error in
                    DispatchQueue.main.async {
                        if workout != nil {
                            let defaultStart = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
                            self.fetchWorkouts(since: defaultStart)
                            completion(true)
                        } else {
                            print("Failed to build workout: \(String(describing: error))")
                            completion(false)
                        }
                    }
                }
            }
        }
    }
}

