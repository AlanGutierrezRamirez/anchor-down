//
//  Constants.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 3/3/26.
//

import Foundation
import SwiftUI
import Combine

class SystemSettings: ObservableObject {
    @Published var healthManager = HealthManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        healthManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

struct Constants{
    static let homeString = "Home"
    static let activityString = "Activity"
    static let progressString = "Progress"
    static let mediaString = "Media"
    static let summaryString = "Summary"

    static let homeIconString = "house"
    static let activityIconString = "figure.walk"
    static let flagIconString = "flag"
    static let playIconString = "play"
    static let listIconString = "list.bullet.rectangle"
    
    static let HomeViewTitleString: String = "Making Fast"
    static let StartingWeightString: String = "Starting Weight"
    static let DaysToGoString: String = "Days to Go"
    static let WeigthChangeString: String = "Weight Change"
    static let LatestShiftString: String = "Latest Shift"
    static let CaloriesBurnedTodayString: String = "Calories Burned Today"
    static let TotalStepsString: String = "Total Steps"
    static let CurrentWeightString: String = "Current Weight"
    static let PreviousWeightString: String = "Previous Weight"
    
    static let JourneyDatesString: String = "Your Journey Dates"
    static let StartDateString : String = "Start Date"
    static let EventDateString : String = "Event Date"
    static let WeightGoalsString : String = "Weight Goals"
    static let StartWeightString : String = "Start Weight"
    static let TargetWeightString : String = "Target Weight"
}

