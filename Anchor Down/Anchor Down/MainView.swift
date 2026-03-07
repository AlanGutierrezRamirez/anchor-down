//
//  HomeView.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 3/3/26.
//

import SwiftUI

struct HomeView: View {
    
    var body : some View {
        TabView {
            Tab("", systemImage: Constants.homeIconString) {
                SummaryView()
            }
            Tab("", systemImage: Constants.activityIconString) {
                ActivityView()
            }
            Tab("", systemImage: Constants.flagIconString) {
                Text(Constants.progressString)
            }
            Tab("", systemImage: Constants.playIconString) {
                Text(Constants.mediaString)
            }
            Tab("", systemImage: Constants.listIconString) {
                LogView()
            }
            
        }
        
    }
    
}

#Preview {
    HomeView()
}
