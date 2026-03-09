//
//  MainView.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 3/3/26.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0: HomeView()
                case 1: ActivityView()
                case 2: Text(Constants.progressString)
                case 3: Text(Constants.mediaString)
                default: LogView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.02, green: 0.05, blue: 0.12).ignoresSafeArea())

            HStack(spacing: 0) {
                TabButton(icon: Constants.homeIconString, isSelected: selectedTab == 0) { selectedTab = 0 }
                TabButton(icon: Constants.activityIconString, isSelected: selectedTab == 1) { selectedTab = 1 }
                TabButton(icon: Constants.flagIconString, isSelected: selectedTab == 2) { selectedTab = 2 }
                TabButton(icon: Constants.playIconString, isSelected: selectedTab == 3) { selectedTab = 3 }
                TabButton(icon: Constants.listIconString, isSelected: selectedTab == 4) { selectedTab = 4 }
            }
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.cyan.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
    }
}


struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(isSelected ? .cyan : .gray)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainView()
}
